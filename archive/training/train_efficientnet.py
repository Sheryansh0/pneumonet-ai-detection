import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Dataset
from torchvision.models import efficientnet_v2_s, EfficientNet_V2_S_Weights
from torch.optim.lr_scheduler import _LRScheduler, CosineAnnealingLR
from torchvision import transforms
import os
import glob
from tqdm import tqdm
import argparse
from PIL import Image
from torch.cuda.amp import GradScaler, autocast # For Mixed Precision

# --- Custom Warmup Scheduler ---
class WarmupCosineAnnealingLR(_LRScheduler):
    def __init__(self, optimizer, warmup_epochs, total_epochs, last_epoch=-1):
        self.warmup_epochs = warmup_epochs
        self.total_epochs = total_epochs
        self.cosine_scheduler = CosineAnnealingLR(optimizer, T_max=total_epochs - warmup_epochs, eta_min=1e-6)
        super().__init__(optimizer, last_epoch)

    def get_lr(self):
        if self.last_epoch < self.warmup_epochs:
            # Linear warmup
            return [base_lr * (self.last_epoch + 1) / self.warmup_epochs for base_lr in self.base_lrs]
        else:
            return self.cosine_scheduler.get_lr()

    def step(self, epoch=None):
        if epoch is None:
            epoch = self.last_epoch + 1
        self.last_epoch = epoch
        if epoch >= self.warmup_epochs:
            self.cosine_scheduler.step(epoch - self.warmup_epochs)
        super().step(epoch)

# --- Transformation Pipelines ---
preprocess_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

train_transform = transforms.Compose([
    transforms.RandomResizedCrop(224, scale=(0.8, 1.0)),
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(15),
    transforms.ColorJitter(brightness=0.3, contrast=0.3),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

# --- Dataset Class ---
class ImageTensorDataset(Dataset):
    def __init__(self, data_dir, transform=None):
        class_names = sorted([d for d in os.listdir(data_dir) 
                              if os.path.isdir(os.path.join(data_dir, d)) and not d.startswith('.')])
        self.class_to_idx = {cls: i for i, cls in enumerate(class_names)}
        self.file_paths = []
        for cls in class_names:
            self.file_paths.extend(glob.glob(os.path.join(data_dir, cls, '*.jpeg')))
            self.file_paths.extend(glob.glob(os.path.join(data_dir, cls, '*.jpg')))
            self.file_paths.extend(glob.glob(os.path.join(data_dir, cls, '*.png')))
        self.transform = transform

    def __len__(self):
        return len(self.file_paths)

    def __getitem__(self, idx):
        file_path = self.file_paths[idx]
        image = Image.open(file_path).convert('RGB')
        class_name = os.path.basename(os.path.dirname(file_path))
        label = self.class_to_idx[class_name]
        if self.transform:
            image = self.transform(image)
        return image, label

# --- Main Training Function ---
def main(args):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")

    train_dataset = ImageTensorDataset(os.path.join('chest_xray', 'train'), transform=train_transform)
    val_dataset = ImageTensorDataset(os.path.join('chest_xray', 'val'), transform=preprocess_transform)

    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True, num_workers=2)
    val_loader = DataLoader(val_dataset, batch_size=args.batch_size, shuffle=False, num_workers=2)
    
    print(f"Class mapping: {train_dataset.class_to_idx}")

    model = efficientnet_v2_s(weights=EfficientNet_V2_S_Weights.IMAGENET1K_V1)
    num_ftrs = model.classifier[1].in_features
    model.classifier[1] = nn.Linear(num_ftrs, len(train_dataset.class_to_idx))
    model = model.to(device)

    criterion = nn.CrossEntropyLoss(label_smoothing=0.1)
    optimizer = optim.AdamW(model.parameters(), lr=args.learning_rate, weight_decay=args.weight_decay)
    
    # Use the new Warmup Scheduler
    scheduler = WarmupCosineAnnealingLR(optimizer, warmup_epochs=5, total_epochs=args.epochs)
    
    # Initialize the Gradient Scaler for AMP
    scaler = GradScaler()

    best_val_accuracy = 0.0

    for epoch in range(args.epochs):
        model.train()
        pbar = tqdm(train_loader, desc=f"Epoch {epoch+1}/{args.epochs} [Training]")
        for inputs, labels in pbar:
            inputs, labels = inputs.to(device), labels.to(device)
            
            # Use autocast for the forward pass
            with autocast():
                outputs = model(inputs)
                loss = criterion(outputs, labels)
            
            optimizer.zero_grad()
            # Scale the loss and call backward()
            scaler.scale(loss).backward()
            # Call step() on the scaler to update the weights
            scaler.step(optimizer)
            # Update the scaler for the next iteration
            scaler.update()

        model.eval()
        val_correct = 0
        with torch.no_grad():
            for inputs, labels in tqdm(val_loader, desc=f"Epoch {epoch+1}/{args.epochs} [Validation]"):
                inputs = inputs.to(device)
                with autocast():
                    outputs = model(inputs)
                _, predicted = torch.max(outputs.data, 1)
                val_correct += (predicted.cpu() == labels).sum().item()
        
        val_accuracy = 100 * val_correct / len(val_dataset)
        print(f"\nEpoch {epoch+1} Validation Accuracy: {val_accuracy:.2f}%")
        
        # Step the scheduler
        scheduler.step()

        if val_accuracy > best_val_accuracy:
            best_val_accuracy = val_accuracy
            torch.save(model.state_dict(), args.save_path)
            print(f"New best model saved to {args.save_path} with accuracy: {best_val_accuracy:.2f}%")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Advanced Training of EfficientNetV2")
    parser.add_argument('--save_path', type=str, default='efficientnet_advanced.pth', help='Path to save the best model')
    parser.add_argument('--epochs', type=int, default=50, help='Number of training epochs')
    parser.add_argument('--batch_size', type=int, default=10, help='Training batch size (can be larger with AMP)')
    parser.add_argument('--learning_rate', type=float, default=5e-5, help='Learning rate for optimizer')
    parser.add_argument('--weight_decay', type=float, default=1e-5, help='Weight decay for AdamW optimizer')
    args = parser.parse_args()
    main(args)


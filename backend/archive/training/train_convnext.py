import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Dataset
from torchvision.models import convnext_tiny, ConvNeXt_Tiny_Weights
from torch.optim.lr_scheduler import CosineAnnealingWarmRestarts
from torchvision import transforms
import os
import glob
from tqdm import tqdm
import argparse
from PIL import Image

# --- Transformation Pipelines ---
# For Validation & Testing (No Augmentation)
preprocess_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

# For Training (With Advanced Data Augmentation)
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

    # Create datasets
    train_dataset = ImageTensorDataset(os.path.join('chest_xray', 'train'), transform=train_transform)
    val_dataset = ImageTensorDataset(os.path.join('chest_xray', 'val'), transform=preprocess_transform)

    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True, num_workers=2)
    val_loader = DataLoader(val_dataset, batch_size=args.batch_size, shuffle=False, num_workers=2)
    
    print(f"Class mapping: {train_dataset.class_to_idx}")

    # Use the convnext_tiny model
    model = convnext_tiny(weights=ConvNeXt_Tiny_Weights.IMAGENET1K_V1)
    num_ftrs = model.classifier[2].in_features
    model.classifier[2] = nn.Linear(num_ftrs, len(train_dataset.class_to_idx))
    model = model.to(device)

    criterion = nn.CrossEntropyLoss()
    
    # --- Fine-Tuning Stage 1: Train the Head ---
    print("\n--- STAGE 1: Training the Classifier Head ---")
    
    # Freeze all layers first
    for param in model.parameters():
        param.requires_grad = False
    # Unfreeze only the final classifier
    for param in model.classifier.parameters():
        param.requires_grad = True

    # Optimizer for the head only
    optimizer = optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=args.learning_rate)
    
    for epoch in range(args.head_epochs):
        model.train()
        pbar = tqdm(train_loader, desc=f"Stage 1 - Epoch {epoch+1}/{args.head_epochs} [Training Head]")
        # (Training loop is the same)
        for inputs, labels in pbar:
            inputs, labels = inputs.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
        # (Validation loop is the same)
        model.eval()
        val_correct = 0
        with torch.no_grad():
            for inputs, labels in tqdm(val_loader, desc=f"Stage 1 - Epoch {epoch+1}/{args.head_epochs} [Validation]"):
                inputs, labels = inputs.to(device), labels.to(device)
                outputs = model(inputs)
                _, predicted = torch.max(outputs.data, 1)
                val_correct += (predicted == labels).sum().item()
        val_accuracy = 100 * val_correct / len(val_dataset)
        print(f"\nStage 1 - Epoch {epoch+1} Validation Accuracy: {val_accuracy:.2f}%")


    # --- Fine-Tuning Stage 2: Unfreeze and Tune Deeper Layers ---
    print("\n--- STAGE 2: Fine-Tuning the Full Model ---")
    
    # Unfreeze all layers
    for param in model.parameters():
        param.requires_grad = True

    # Set up a new optimizer with different learning rates
    optimizer = optim.AdamW([
        {'params': model.features.parameters(), 'lr': args.learning_rate / 10}, # Lower LR for the body
        {'params': model.classifier.parameters(), 'lr': args.learning_rate}     # Higher LR for the head
    ], weight_decay=1e-5)

    scheduler = CosineAnnealingWarmRestarts(optimizer, T_0=10, T_mult=1, eta_min=1e-6)
    best_val_accuracy = 0.0

    for epoch in range(args.full_epochs):
        model.train()
        pbar = tqdm(train_loader, desc=f"Stage 2 - Epoch {epoch+1}/{args.full_epochs} [Fine-Tuning]")
        # (Training loop is the same)
        for inputs, labels in pbar:
            inputs, labels = inputs.to(device), labels.to(device)
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

        model.eval()
        val_correct = 0
        with torch.no_grad():
            for inputs, labels in tqdm(val_loader, desc=f"Stage 2 - Epoch {epoch+1}/{args.full_epochs} [Validation]"):
                inputs, labels = inputs.to(device), labels.to(device)
                outputs = model(inputs)
                _, predicted = torch.max(outputs.data, 1)
                val_correct += (predicted == labels).sum().item()
        
        val_accuracy = 100 * val_correct / len(val_dataset)
        print(f"\nStage 2 - Epoch {epoch+1} Validation Accuracy: {val_accuracy:.2f}%")
        
        scheduler.step()

        if val_accuracy > best_val_accuracy:
            best_val_accuracy = val_accuracy
            torch.save(model.state_dict(), args.save_path)
            print(f"New best model saved to {args.save_path} with accuracy: {best_val_accuracy:.2f}%")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fine-tune a Pneumonia Detection Model.")
    parser.add_argument('--save_path', type=str, default='convnext_pneumonia_finetuned.pth', help='Path to save the best model')
    parser.add_argument('--head_epochs', type=int, default=5, help='Number of epochs to train the head')
    parser.add_argument('--full_epochs', type=int, default=25, help='Number of epochs to fine-tune the full model')
    parser.add_argument('--batch_size', type=int, default=16, help='Training batch size')
    parser.add_argument('--learning_rate', type=float, default=1e-4, help='Base learning rate for optimizer')

    args = parser.parse_args()
    main(args)
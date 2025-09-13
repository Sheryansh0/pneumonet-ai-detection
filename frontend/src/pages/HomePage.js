import React, { useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/ui/button";
import { Scan, ArrowRight, Shield, Zap } from "lucide-react";

const HomePage = () => {
  const navigate = useNavigate();
  const videoRef = useRef(null);

  useEffect(() => {
    if (videoRef.current) {
      videoRef.current.play().catch(console.error);
    }
  }, []);

  const handleAnalyzeClick = () => {
    navigate("/upload");
  };

  return (
    <div className="relative min-h-screen overflow-hidden bg-gradient-to-br from-slate-900 via-blue-900 to-slate-800">
      {/* Video Background */}
      <div className="absolute inset-0 z-0">
        <video
          ref={videoRef}
          className="w-full h-full object-cover opacity-40"
          autoPlay
          loop
          muted
          playsInline
        >
          <source
            src="https://res.cloudinary.com/djfhbyk7a/video/upload/v1757361336/Pneumonia_Detection_Video_Generation_kzptix.mp4"
            type="video/mp4"
          />
        </video>
        <div className="absolute inset-0 bg-gradient-to-br from-blue-900/80 via-slate-900/70 to-cyan-900/60"></div>
      </div>

      {/* Animated Background Elements */}
      <div className="absolute inset-0 z-10">
        <div className="absolute top-20 left-20 w-32 h-32 bg-cyan-500/10 rounded-full blur-xl animate-pulse"></div>
        <div
          className="absolute bottom-40 right-32 w-48 h-48 bg-blue-500/10 rounded-full blur-2xl animate-bounce"
          style={{ animationDuration: "3s" }}
        ></div>
        <div
          className="absolute top-1/2 left-1/4 w-24 h-24 bg-indigo-500/10 rounded-full blur-lg animate-ping"
          style={{ animationDuration: "2s" }}
        ></div>
      </div>

      {/* Main Content */}
      <div className="relative z-20 flex flex-col items-center justify-center min-h-screen px-6">
        {/* Header */}
        <div className="mb-8 text-center transform hover:scale-105 transition-all duration-700">
          <div className="flex items-center justify-center mb-4">
            <div className="p-2 rounded-full bg-gradient-to-r from-cyan-500/10 to-blue-500/10 backdrop-blur-md border border-white/20">
              <img
                src="https://res.cloudinary.com/djfhbyk7a/image/upload/v1757540079/cropped_circle_image_mg7gem.png"
                alt="PneumoNet Logo"
                className="h-16 w-16 rounded-full object-cover ring-2 ring-cyan-400/30"
              />
            </div>
          </div>
          <h1 className="text-6xl font-bold mb-4 bg-gradient-to-r from-white via-cyan-100 to-blue-100 bg-clip-text text-transparent leading-tight">
            PneumoNet
            <br />
            <span className="text-5xl bg-gradient-to-r from-cyan-400 to-blue-400 bg-clip-text text-transparent">
              AI Pneumonia Detection
            </span>
          </h1>
          <p className="text-xl text-slate-300 max-w-2xl mx-auto leading-relaxed">
            Advanced AI-powered analysis for rapid and accurate pneumonia
            detection from chest X-rays. Get instant results with high precision
            diagnostic insights.
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12 max-w-4xl mx-auto">
          {[
            {
              icon: <Scan className="h-8 w-8 text-cyan-400" />,
              title: "AI-Powered Analysis",
              description:
                "Advanced deep learning algorithms for precise detection",
            },
            {
              icon: <Zap className="h-8 w-8 text-blue-400" />,
              title: "Instant Results",
              description: "Get accurate predictions in seconds, not hours",
            },
            {
              icon: <Shield className="h-8 w-8 text-indigo-400" />,
              title: "Medical Grade",
              description: "Trained on thousands of validated medical images",
            },
          ].map((feature, index) => (
            <div
              key={index}
              className="group p-6 rounded-2xl bg-white/5 backdrop-blur-md border border-white/10 hover:bg-white/10 transition-all duration-500 transform hover:scale-105 hover:-translate-y-2"
              style={{
                animationDelay: `${index * 0.2}s`,
                animation: "fadeInUp 1s ease-out forwards",
              }}
            >
              <div className="mb-4 p-3 rounded-xl bg-gradient-to-r from-slate-800/50 to-slate-700/50 w-fit mx-auto group-hover:scale-110 transition-transform duration-300">
                {feature.icon}
              </div>
              <h3 className="text-lg font-semibold text-white mb-2">
                {feature.title}
              </h3>
              <p className="text-slate-300 text-sm leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>

        {/* CTA Button */}
        <div className="transform hover:scale-110 transition-all duration-500">
          <Button
            onClick={handleAnalyzeClick}
            className="group relative px-12 py-6 text-xl font-semibold bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-500 hover:to-blue-500 text-white rounded-2xl shadow-2xl hover:shadow-cyan-500/25 transition-all duration-500 border-0 overflow-hidden"
          >
            <span className="absolute inset-0 bg-gradient-to-r from-white/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></span>
            <span className="relative flex items-center gap-3">
              Analyze Now
              <ArrowRight className="h-6 w-6 group-hover:translate-x-2 transition-transform duration-300" />
            </span>
          </Button>
        </div>

        {/* Bottom Stats */}
        <div className="mt-16 mb-8">
          <div className="flex items-center justify-center gap-8 text-slate-400 text-sm">
            <div className="text-center">
              <div className="text-2xl font-bold text-cyan-400">88.9%</div>
              <div>Accuracy</div>
            </div>
            <div className="w-px h-8 bg-slate-600"></div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-400">1.36s</div>
              <div>Avg Analysis Time</div>
            </div>
            <div className="w-px h-8 bg-slate-600"></div>
            <div className="text-center">
              <div className="text-2xl font-bold text-indigo-400">865</div>
              <div>Scans Tested</div>
            </div>
          </div>
        </div>
      </div>

      {/* Custom CSS for animations */}
      <style>
        {`
          @keyframes fadeInUp {
            from {
              opacity: 0;
              transform: translateY(40px);
            }
            to {
              opacity: 1;
              transform: translateY(0);
            }
          }
        `}
      </style>
    </div>
  );
};

export default HomePage;

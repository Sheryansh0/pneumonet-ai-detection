import React, { useState, useEffect } from "react";
import { Card } from "./ui/card";
import { Button } from "./ui/button";
import { CheckCircle, AlertCircle, Loader2, Wifi } from "lucide-react";
import pneumoniaAPI from "../services/api";

const ConnectionStatus = ({ className = "" }) => {
  const [status, setStatus] = useState("checking"); // 'checking', 'online', 'offline'
  const [lastChecked, setLastChecked] = useState(null);

  const checkConnection = async () => {
    setStatus("checking");
    try {
      const result = await pneumoniaAPI.checkHealth();
      if (result.success) {
        setStatus("online");
      } else {
        setStatus("offline");
      }
    } catch (error) {
      console.error("Health check failed:", error);
      setStatus("offline");
    }
    setLastChecked(new Date());
  };

  useEffect(() => {
    checkConnection();
    // Check every 30 seconds
    const interval = setInterval(checkConnection, 30000);
    return () => clearInterval(interval);
  }, []);

  const getStatusConfig = () => {
    switch (status) {
      case "online":
        return {
          icon: <CheckCircle className="h-4 w-4" />,
          text: "AI Server Online",
          color: "text-green-400",
          bgColor: "bg-green-500/10 border-green-500/20",
        };
      case "offline":
        return {
          icon: <AlertCircle className="h-4 w-4" />,
          text: "AI Server Offline",
          color: "text-red-400",
          bgColor: "bg-red-500/10 border-red-500/20",
        };
      default:
        return {
          icon: <Loader2 className="h-4 w-4 animate-spin" />,
          text: "Checking...",
          color: "text-yellow-400",
          bgColor: "bg-yellow-500/10 border-yellow-500/20",
        };
    }
  };

  const config = getStatusConfig();

  return (
    <Card
      className={`p-4 bg-white/5 backdrop-blur-md border border-white/10 ${className}`}
    >
      <div className="flex items-center justify-between">
        <div
          className={`flex items-center gap-2 px-3 py-2 rounded-lg border ${config.bgColor}`}
        >
          <Wifi className="h-4 w-4 text-slate-400" />
          {config.icon}
          <span className={`text-sm font-medium ${config.color}`}>
            {config.text}
          </span>
        </div>

        <Button
          onClick={checkConnection}
          size="sm"
          className="px-4 py-2 text-sm font-medium bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-500 hover:to-blue-500 text-white rounded-lg shadow-lg hover:shadow-cyan-500/25 transition-all duration-300 transform hover:scale-105"
          disabled={status === "checking"}
        >
          Refresh
        </Button>
      </div>

      {lastChecked && (
        <p className="text-xs text-slate-500 mt-2">
          Last checked: {lastChecked.toLocaleTimeString()}
        </p>
      )}
    </Card>
  );
};

export default ConnectionStatus;

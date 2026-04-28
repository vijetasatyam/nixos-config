{...}: {
  services.mako = {
    enable = true;
    font = "JetBrainsMono Nerd Font 11";
    padding = "15";
    margin = "10";
    width = 350;
    borderSize = 3;
    borderRadius = 12;
    backgroundColor = "#282a36FA"; # Dracula BG with slight transparency
    borderColor = "#bd93f9"; # Dracula Purple
    textColor = "#f8f8f2"; # Dracula Foreground
    progressColor = "over #44475a";
    defaultTimeout = 5000;
  };
}

# Scan-Echo

ScanEcho is an efficient Bash tool developed by **Samuel García (SamuCrow)**. It's designed to simplify the process of performing various scans on an IP address using Nmap.

## How does it look?

![Captura de pantalla 2024-12-11 154514](https://github.com/user-attachments/assets/f5b94f7f-989a-4631-a87e-d5b0a5345e80)

## Key Features

- Versatile scanning options: Provides multiple scanning options adaptable to different needs, including stealth scans, as well as detecting open ports and vulnerabilities.
- Easy to use: Offers an intuitive terminal-based interface with clear instructions, making it accessible even for users with basic knowledge of bash and nmap.
- Clear and organized results: Presents scan output in a structured way, making it easier to interpret and analyze the collected data.

## Use

```bash
git clone https://github.com/samucrow/ScanEcho.git
cd ScanEcho
chmod 766 ScanEcho.sh
sudo ./ScanEcho.sh
```

When you have cloned the repository, if you want to run the script from anywhere, do this:

```bash
sudo chmod +x ScanEcho.sh
sudo mv ScanEcho.sh /usr/bin/scan-echo
scan-echo
```

![Solar Insurance Logo](./.doc/img/logo_w_text.png)

# Solar Insurance DApp Smart Contract

FFHS PiBS, HS 2023/2024, Blockchain, Fabian Diemand  
Dozenten: Malik El Bay, Oliver Dressler  
Repository Frontend: https://github.com/FabianDiemand/solar-insurance-frontend  
Repository Smart Contract:  https://github.com/FabianDiemand/solar-insurance-smartcontract  

## Info
Der Smart Contract ist im Rahmen einer Semesterarbeit des Moduls Blockchain an der Fernfachhochschule Schweiz entstanden. Weitere Informationen zu der Arbeit, eine Beschreibung des zugehörigen Frontends, der API und der Bedingungen im Contract sind in der [Dokumentation](./.doc/doc.md) zu finden.

## Deployment
### :bangbang: Wichtig :bangbang:
Für die Inbetriebnahme des Frontend ist grundsätzlich kein erneutes Deployment des Smart Contracts notwendig. Soll lediglich die Grundfunktionsweise der DApp getestet werden, kann diese Anleitung ignoriert werden und direkt mit der [Installation des Frontends](https://github.com/FabianDiemand/solar-insurance-frontend/blob/main/.doc/doc.md#5-installation) begonnen werden.

### Anforderungen
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Visual Studio Code Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Anleitung
1. Clone das Repository <br>
   ```bash
   git clone git@github.com:FabianDiemand/solar-insurance-smartcontract.git
   ```

2. Öffne das geclonte Repository in Visual Studio Code <br>
   ```bash
   code solar-insurance-smartcontract
   ```

3. **EMPFOHLEN:** Öffne das Projekt im entsprechenden Dev Container *(Ctrl + P -> 'Dev Containers: Reopen in Container')* <br>
   ![Dev Con](./.doc/img/devcon.png) <br><br>

   **ALTERNATIV:** Installiere alle Abhängigkeiten lokal
   ```bash
   npm install
   ```

4. Kompiliere den Smart Contract mit Hardhat
   ```bash
   make hardhat-compile
   ```

   Der erwartete Output informiert über den Status der Kompilation:
   > ✔ Help us improve Hardhat with anonymous crash reports & basic usage data? (Y/n) · n <br>
   > Downloading compiler 0.8.22 <br>
   > Compiled 1 Solidity file successfully (evm target: paris). <br>
  
  <br>

5. Setze die gewünschte Ziel-Blockchain als ENV Variable und deploye den Smart Contract mit Hardhat
   ```bash
   export CONTRACT_CHAIN=<target-chain>
   make hardhat-deploy
   ```

   Der erwartete Output sollte die Adresse des Smart Contracts auf der Ziel-Blockchain enthalten:
   > Contract address: 0x1c668eafa578dc863e4776407a175341aa5d0965

   <br>

6. Setze die Adresse des Smart Contract als ENV Variable und verifiziere den Smart Contract mit Hardhat, um den Source Code zu publizieren.
   ```bash
   export CONTRACT_ADDR=<contract-address>
   make hardhat-verify
   ```

   Der erwartete Output informiert über den Status der Verifizierung und generiert einen Link zum veröffentlichten Source Code auf Etherscan
   > Successfully submitted source code for contract <br>
   > contracts/SolarInsurance.sol:SolarInsurance at 0x1c668eafa578dc863e4776407a175341aa5d0965 <br>
   > for verification on the block explorer. Waiting for verification result... <br>
   >
   > Successfully verified contract SolarInsurance on the block explorer. <br>
   > https://sepolia.etherscan.io/address/0x1c668eafa578dc863e4776407a175341aa5d0965#code <br>
  
  <br>

7. Damit das Frontend mit dem richtigen Vertrag interagiert, müssen die Variablen im .env-File des [solar-insurance-frontend](https://github.com/FabianDiemand/solar-insurance-frontend) Projekts entsprechend angepasst werden.

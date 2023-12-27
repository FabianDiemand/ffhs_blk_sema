![Solar Insurance Logo](./img/logo_w_text.png)

# Solar Insurance DApp Smart Contract

FFHS PiBS, HS 2023/2024, Blockchain, Fabian Diemand  
Dozenten: Malik El Bay, Oliver Dressler  
Repository Smart Contract:  https://github.com/FabianDiemand/solar-insurance-smartcontract  
Repository Frontend: https://github.com/FabianDiemand/solar-insurance-frontend  

---

## Inhalt
* [1 Einleitung](#1-einleitung)
* [2 Frontend](#2-deployment)
* [3 Erklärung Smart Contract](#3-erklärung-smart-contract)
  * [3.1 Konstanten](#31-konstanten)
  * [3.2 Schnittstellen](#32-schnittstellen)
  * [3.3 Bedingungen](#33-bedingungen)
* [4 Technologien und Services](#4-technologien-und-services)
  * [4.1 Solidity](#41-solidity)
  * [4.2 Remix Ethereum IDE](#42-remix-ethereum-ide)
  * [4.3 VS Code und Docker](#43-vs-code-und-docker)
  * [4.4 Hardhat](#44-hardhat)
  * [4.5 Sepolia Testchain](#45-sepolia-testchain)
  * [4.6 Weitere](#46-weitere)
* [5 Deployment](#5-deployment)


---

## 1 Einleitung
Im Rahmen des Moduls Blockchain wurde sich mit Technologien, Anwendungsfällen und rechtlich-wirtschaftlichen Themen rund um die namensgebende Datenstruktur befasst. Teile des Gelernten sollten im Rahmen einer Semesterarbeit mit einer Literatur- oder Engineering-Arbeit angewandt werden.

Im Rahmen diese Semesterarbeit wurde ein Smart Contract geschrieben, der die Policies einer Versicherung für Betreiber einer Photovoltaik-Anlage (fortan PV-Anlage) modelliert. Der versicherte Schaden ist der finanzielle Mehraufwand, durch den Bezug von Strom aus dem Hauptnetz anstelle der eigenen PV-Anlage. Als Indikator für einen Schadenfall wird die Anzahl Sonnenscheinstunden pro Jahr herangezogen.

Die Erkenntnis, dass dieser Indikator nicht alleine relevant für eine Aussage über das Auftreten und das Ausmass eines potenziellen Schadens ist, ist für den Realitätsbezug relevant. Für die Semesterarbeit wird diese Feststellung nicht weiter verarbeitet. Ebenso werden Systemabhängigkeiten von Dritt-APIs zur Datenabfrage und externen Services (namentlich Chainlink) nur im Entwurf erwähnt. Der Fokus liegt auf der Umsetzung des Smart Contracts, dessen Deployment, Verifizierung und der Interaktion mit diesem durch eine grafische Schnittstelle.

## 2 Frontend
Die GUI der Solar Insurance DApp setzt sich aus einer Landing Page ('Insurance') und einer Demo Ansicht ('Demo') zusammen. Die Landing Page bildet die Zugriffsschnittstelle auf die für eine produktive Verwendung notwendigen Funktionen des Smart Contracts. Die Demo Ansicht hilft bei der Verwendung der DApp zu Demo und Test-Zwecken. Sie erlaubt Zustandsänderungen, die üblicherweise durch Interaktionen mit anderen Nutzern oder APIs ('Fund Contract', 'Create Sunshine Record') oder unter stärkeren Einschränkungen ('File Claim') möglich sind.

Weitere Details zum Smart Contract sind in der Dokumentation zum [Frontend](https://github.com/FabianDiemand/solar-insurance-frontend), sowie in der zugehörigen Semesterarbeit dokumentiert.

## 3 Erklärung Smart Contract
Die Solar Insurance DApp setzt sich aus einem Frontend und einem Smart Contract zusammen. Der Smart Contract ist unter der Adresse [0x1c668eafa578dc863e4776407a175341aa5d0965](https://sepolia.etherscan.io/address/0x1c668eafa578dc863e4776407a175341aa5d0965) auf der Seplia Testchain bereitgestellt. Deployment und Code des Contracts, sowie die ABI, Transaktionen und Event Logs können in Etherscan eingesehen werden.

### 3.1 Konstanten

#### Berechnungskonstanten

#### Risiko-Levels

### 3.2 Schnittstellen
|Name   |Parameter   |Beschreibung   |  
|---|---|---|
||||

### 3.3 Bedingungen
|Name |Parameter |Beschreibung |
|---|---|---|
||||

## 4 Technologien und Services

### 4.1 Solidity

### 4.2 Remix Ethereum IDE

### 4.3 VS Code und Docker

### 4.4 Hardhat

### 4.5 Sepolia Testchain

### 4.6 Weitere

#### Ethers.js

#### Makefile

## 5 Deployment
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
   ![Dev Con](./img/devcon.png) <br><br>

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


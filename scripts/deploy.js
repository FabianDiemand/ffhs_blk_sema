const { ethers } = require('hardhat');

async function main(){
  const SolarInsurance = await ethers.getContractFactory('SolarInsurance');

  const solarInsurance = await SolarInsurance.deploy();
  console.log('Contract address:', solarInsurance.address);
}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error);
  process.exit(1);
});
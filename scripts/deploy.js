const { ethers } = require('hardhat');

async function main(){
  // factory as an abstraction for smart contract instances
  const solarInsuranceFactory = await ethers.getContractFactory('SolarInsurance');

  // results in a promise resolving to a contract instance
  const solarInsurance = await solarInsuranceFactory.deploy();
  console.log('Contract address:', solarInsurance.address);
}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error);
  process.exit(1);
});
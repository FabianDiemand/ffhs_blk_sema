const ALCHEMY_API_URL = process.env.ALCHEMY_API_URL;
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const METAMASK_PRIVATE_KEY = process.env.METAMASK_PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;

// Get instance of the solar insurance contract to get access to the contract abi
const contract = require('../artifacts/contracts/SolarInsurance.sol/SolarInsurance.json');
const ethers = require('ethers');

const alchemyProvider = new ethers.providers.JsonRpcProvider(ALCHEMY_API_URL);
const signer = new ethers.Wallet(METAMASK_PRIVATE_KEY, alchemyProvider);
const solarInsuranceContract = new ethers.Contract(CONTRACT_ADDRESS, contract.abi, signer);

async function main(){
  // call the owner function of the smart contract
  const owner = await solarInsuranceContract.owner();
  console.log('The contract owner is:', owner);
}

main();
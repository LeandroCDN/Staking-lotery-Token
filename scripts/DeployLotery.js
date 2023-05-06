const hre = require("hardhat");
require('dotenv').config();
const fs = require("fs");

function saveAddressesToFile(addresses) {
  const data = JSON.stringify(addresses);
  fs.writeFileSync("addresses.json", data);
}
const addresses = {
  lotery: "",
  randomGenerator: ""
};

const MUMBAI_PRIVATE_KEY = process.env.MUMBAI_PRIVATE_KEY;

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(hre.config.networks.mumbai.url);
  const signer = new ethers.Wallet(MUMBAI_PRIVATE_KEY,provider);
  provider.getSigner(signer.address);
  console.log(signer.toString());

  const tiketCost = ethers.utils.parseEther("1"); // 1000 token
  const stableFee = "40";  
  const house = "0xe027625a79C62E2967a4Ac3B5aA11a7a07cca7fd"; 
  const percentForWiners = [50,20,15,10,5]; 
  const RandomGenerator = "0xb141C214F14E6C1B8B42026e58cB24129162456B"; 
  const ticketCoin = "0xD6920eeAF9b9bc7288765F72B4d6Da3e47308464"

  const Lotery = await hre.ethers.getContractFactory("Lotery", {
    optimizer: {
      enabled: true,
      runs: 5000,
    }
  });

  const lotery = await Lotery.deploy(    
    tiketCost, stableFee, house, percentForWiners, RandomGenerator, ticketCoin
  );
  await lotery.deployed();
  const WAIT_BlOCKS = 12;
  await lotery.deployTransaction.wait(WAIT_BlOCKS);

  const vrf = await hre.ethers.getContractFactory("RandomGenerator")
  const randomGenerator = await vrf.attach(RandomGenerator).connect(signer);
  await randomGenerator.setCode(lotery.address,{
    gasLimit: 1000000
  });
  await randomGenerator.toggleOwnerList(lotery.address,{
    gasLimit: 1000000
  });  

  console.log(`Contrato Lotery desplegado en ${lotery.address}`);
  
  await run(`verify:verify`,{
    address:lotery.address,
    constructorArguments:[tiketCost,stableFee,house,percentForWiners, RandomGenerator,ticketCoin],
  })


  addresses.lotery = lotery.address;
  addresses.randomGenerator = randomGenerator.address;
  saveAddressesToFile(addresses);
}
//  npx hardhat run ./scripts/deploy.js  --network mumbai
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// Testnet 3/05/23
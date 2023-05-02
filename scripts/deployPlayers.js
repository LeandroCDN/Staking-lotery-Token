const hre = require("hardhat");
require('dotenv').config();
//https://mumbai.polygonscan.com/address/0x64177A1976C8B10B54d4bB311Fa193f6143e17F5#code

async function main() {
  const lotery = "0x0E99dD4e731875f5592Ad852E13C376b0A04F3B3"; 
  
  const Players = await hre.ethers.getContractFactory("CreatePlayersInLotery", {
    optimizer: {
      enabled: true,
      runs: 5000,
    },
    // actualizar la ruta del archivo de artefactos
    contractName: "contracts/CreatePlayersInLotery.sol:CreatePlayersInLotery"
  });

  const createPlayersInLotery = await Players.deploy(lotery);
  await createPlayersInLotery.deployed();
  const WAIT_BlOCKS = 12;
  await createPlayersInLotery.deployTransaction.wait(WAIT_BlOCKS);

  console.log(`Contrato Lotery desplegado en ${createPlayersInLotery.address}`);
  
  await run(`verify:verify`,{
    address:createPlayersInLotery.address,
    constructorArguments:[lotery],
    contract: "contracts/CreatePlayersInLotery.sol:CreatePlayersInLotery"
  })

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
const hre = require("hardhat");

async function main() {
  const PATOAddress = "0x... (la dirección del contrato de PatoVerde)";
  const rewardAddress = "0x... (la dirección del contrato de recompensa)";
  const deployerAddress = "0x... (la dirección del contrato de recompensa)";


  const Staking = await hre.ethers.getContractFactory("Staking.sol");
  const staking = await Staking.deploy(    
    PATOAddress, rewardAddress, deployerAddress    
  );

  await staking.deployed();

  console.log(`Contrato Staking desplegado en ${staking.address}`);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
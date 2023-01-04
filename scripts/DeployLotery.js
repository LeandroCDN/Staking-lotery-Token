const hre = require("hardhat");

async function main() {
  const winAmount = ethers.utils.parseEther("1000"); // 1000 token
  const numberCost = ethers.utils.parseEther("0.1"); // 0.1 token
  const tokenAddress = "0x... (la dirección del contrato de token)";
  

  const Lotery = await hre.ethers.getContractFactory("Lotery.sol");

  const lotery = await Lotery.deploy(    
    tokenAddress, winAmount, numberCost
  );

  await lotery.deployed();

  console.log(`Contrato Lotery desplegado en ${lotery.address}`);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
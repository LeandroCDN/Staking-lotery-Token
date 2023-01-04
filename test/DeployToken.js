const { deployments, ethers } = require("hardhat");

async function main() {
  const houseWallet = "0x... (la dirección de la billetera de la casa)";
  const loteyContract = "0x... (la dirección del contrato de la lotería)";
  const stakingContract = "0x... (la dirección del contrato de staking)";
  const salesAndLiquidity = "0x... (la dirección del contrato de ventas y liquidez)";
  const deployer = ethers.provider.getSigner();

  const compiledContract = await deployments.compile("path/to/Token.sol");

  const deployedContract = await deployments.deploy(compiledContract, [
    houseWallet,
    loteyContract,
    stakingContract,
    salesAndLiquidity,
  ]);
}

main()
  .then(() => console.log("The contract has been deployed"))
  .catch((error) => console.error(error));

const hre = require("hardhat");

async function main() {
  const houseWallet = "0x... (la dirección de la billetera de la casa)";
  const loteyContract = "0x... (la dirección del contrato de la lotería)";
  const stakingContract = "0x... (la dirección del contrato de staking)";
  const salesAndLiquidity = "0x... (la dirección del contrato de ventas y liquidez)";

  const Token = await deployments.compile("Token");

  const token = await Token.deploy(
    houseWallet,
    loteyContract,
    stakingContract,
    salesAndLiquidity,
  );
  await token.deployed();

  console.log(
    `Contrato TOKEN deployed to ${token.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

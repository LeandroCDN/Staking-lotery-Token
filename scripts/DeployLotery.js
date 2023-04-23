const hre = require("hardhat");

async function main() {
  //mainet
  const tiketCost = ethers.utils.parseEther("1"); // 1000 token
  const stableFee = "40";  
  const house = "0xe027625a79C62E2967a4Ac3B5aA11a7a07cca7fd"; 
  const percentForWiners = [50,20,15,10,5]; 
  const RandomGenerator = "0x55112c41a3876a7b9cd3960dc754f53f8b6a7fd2"; 
  const ticketCoin = "0xD6920eeAF9b9bc7288765F72B4d6Da3e47308464"

  const Lotery = await hre.ethers.getContractFactory("Lotery", {
    optimizer: {
      enabled: true,
      runs: 2000,
    }
  });

  const lotery = await Lotery.deploy(    
    tiketCost, stableFee, house, percentForWiners, RandomGenerator, ticketCoin
  );

  await lotery.deployed();
  const WAIT_BlOCKS = 12;
  await lotery.deployTransaction.wait(WAIT_BlOCKS);

  console.log(`Contrato Lotery desplegado en ${lotery.address}`);
  
  await run(`verify:verify`,{
    address:lotery.address,
    constructorArguments:[tiketCost,stableFee,house,percentForWiners, RandomGenerator,ticketCoin],
  })

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
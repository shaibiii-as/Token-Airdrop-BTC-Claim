async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Token = await ethers.getContractFactory("PTPMock");
  const token = await Token.deploy();
  await token.deployed();

  console.log("Token address:", token.address);

  const MiniAdoptionAmpifier = await ethers.getContractFactory(
    "miniAdoptionAmpifier"
  );
  const miniAdoptionAmpifier = await MiniAdoptionAmpifier.deploy(
    //Time to start the contract in Unix formate
    Math.floor(Date.now() / 1000),
    token.address
  );
  await miniAdoptionAmpifier.deployed();
  console.log("MiniAdoptionAmpifier address:", miniAdoptionAmpifier.address);

  // Updating miniAA address into PTP
  const tx = await token.setRewardMinter(miniAdoptionAmpifier.address);
  if (tx) {
    const rewardMinter = await token.rewardMinter();
    const ptpToken = await miniAdoptionAmpifier.ptpToken();

    console.log("Reward Minter: ", rewardMinter);
    console.log("ptpToken: ", ptpToken);

    const msg =
      rewardMinter === miniAdoptionAmpifier.address &&
      ptpToken === token.address
        ? "Every thing is Fine."
        : "Something went wrong";
    console.log(msg);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

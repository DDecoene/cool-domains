const main = async () => {
    const domainContractFactory = await hre.ethers.getContractFactory('Domains');
    const domainContract = await domainContractFactory.deploy("focus");
    await domainContract.deployed();
  
    console.log("Contract deployed to:", domainContract.address);
  
    // CHANGE THIS DOMAIN TO SOMETHING ELSE! I don't want to see OpenSea full of bananas lol
    let txn = await domainContract.register("zen",  {value: hre.ethers.utils.parseEther('0.5')});
    await txn.wait();
    console.log("Minted domain zen.focus");
  
    txn = await domainContract.setRecord("zen", "Gardens are not made by singing 'Oh, how beautiful,' and sitting in the shade. [Rudyard Kipling]");
    await txn.wait();
    console.log("Set record for zen.focus");
  
    const address = await domainContract.getAddress("zen");
    console.log("Owner of domain zen:", address);
  
    const balance = await hre.ethers.provider.getBalance(domainContract.address);
    console.log("Contract balance:", hre.ethers.utils.formatEther(balance));
  }
  
  const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
  
  runMain();
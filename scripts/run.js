const main = async () => {
    const [owner, randomPerson] = await hre.ethers.getSigners();
    const domainContractFactory = await hre.ethers.getContractFactory('Domains');
    const domainContract = await domainContractFactory.deploy("focus");
    await domainContract.deployed();
    console.log("Contract deployed to:", domainContract.address);
    console.log("Contract deployed by:", owner.address);

    let txn = await domainContract.register("zen", { value: hre.ethers.utils.parseEther('0.5') });
    await txn.wait();

    const domainOwner = await domainContract.getAddress("zen");
    console.log("Owner of domain:", domainOwner);

    txn = await domainContract.setIPFSCid("zen", "ededede");
    await txn.wait();

    const ipfscid = await domainContract.IPFSCid("zen");
    console.log("IPFS CID:", ipfscid);

    const balance = await hre.ethers.provider.getBalance(domainContract.address);
    console.log("Contract balance:", hre.ethers.utils.formatEther(balance));
};

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
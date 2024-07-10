import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";

describe("Contract", () => {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deploy() {
    const startingTime = await time.latest();
    const duration = 10 * 86400; // 10 days
    const interval = 3 * 60; // 3 mins
    const vestingAmount = ethers.parseEther("1000");

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const VestingWallet = await hre.ethers.getContractFactory("VestingWallet");
    const DummyToken = await hre.ethers.getContractFactory("DummyERC20");
    const dummyToken = await DummyToken.deploy();

    const vestingContract = await VestingWallet.deploy(
      otherAccount.address,
      startingTime,
      duration,
      interval
    );
    await dummyToken.transfer(vestingContract.target, vestingAmount);

    return {
      startingTime,
      duration,
      interval,
      vestingAmount,
      vestingContract,
      dummyToken,
      owner,
      otherAccount,
    };
  }

  it("deployment", async () => {
    const data = await deploy();
    expect(data.startingTime).to.equal(await data.vestingContract.start());
  });

  it("claim after 3 mins", async () => {
    const {
      startingTime,
      duration,
      interval,
      vestingAmount,
      vestingContract,
      dummyToken,
      owner,
      otherAccount,
    } = await deploy();

    // await ethers.provider.send("evm_increaseTime", [180]);
    // await ethers.provider.send("evm_mine", []);

    await vestingContract.release(dummyToken.target);

    await ethers.provider.send("evm_increaseTime", [180]);
    await ethers.provider.send("evm_mine", []);

    await vestingContract.release(dummyToken.target);

    await ethers.provider.send("evm_increaseTime", [170]);
    await ethers.provider.send("evm_mine", []);

    await vestingContract.release(dummyToken.target);


    // const total =
    //   (await dummyToken.balanceOf(vestingContract.target)) +
    //   (await vestingContract.released(dummyToken.target));

    // const latestBlockTime = await time.latest();

    // console.log(total, BigInt(latestBlockTime - startingTime), BigInt(duration));
    // console.log(startingTime, await vestingContract.start());
    // const expectedAmount =
    //   (total * BigInt(latestBlockTime - startingTime)) / BigInt(duration);
    // console.log(expectedAmount);
    // await expect()
    //   .to.emit(vestingContract, "ERC20Released")
    //   .withArgs(dummyToken.target, expectedAmount);
  });
});

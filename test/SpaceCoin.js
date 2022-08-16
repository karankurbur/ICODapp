const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SpaceCoin", function () {
  let contract;
  let owner;
  let treasury;
  let fakeIcoAddress;
  let acc1;

  const resetContract = async () => {
    [owner, treasury, fakeIcoAddress, acc1] = await ethers.getSigners();
    const SpaceCoin = await ethers.getContractFactory("SpaceCoin");
    const spaceCoin = await SpaceCoin.deploy(
      treasury.address,
      fakeIcoAddress.address
    );
    await spaceCoin.deployed();
    contract = spaceCoin;
  };
  describe("Tax", function () {
    beforeEach(async function () {
      await resetContract();
    });

    it("should allow owner to enable tax", async function () {
      await contract.enableTax();
      expect(await contract.taxEnabled()).to.equal(true);
    });

    it("should allow owner to disable tax", async function () {
      await contract.enableTax();
      await contract.disableTax();
      expect(await contract.taxEnabled()).to.equal(false);
    });

    it("should fail to update tax boolean to the same value", async function () {
      await expect(contract.disableTax()).to.be.revertedWith(
        "tax needs to be enabled"
      );
      await contract.enableTax();
      await expect(contract.enableTax()).to.be.revertedWith("tax is disabled");
    });
  });

  describe("Transfers", function () {
    beforeEach(async function () {
      await resetContract();
    });

    it("should mint correctly with tax enabled", async function () {
      await contract.enableTax();
      await contract.connect(fakeIcoAddress).mint(acc1.address, 100);
      expect(await contract.balanceOf(acc1.address)).to.equal(98);
      expect(await contract.balanceOf(treasury.address)).to.equal(2);
    });

    it("should mint correctly with tax disabled", async function () {
      await contract.connect(fakeIcoAddress).mint(acc1.address, 100);
      expect(await contract.balanceOf(acc1.address)).to.equal(100);
      expect(await contract.balanceOf(treasury.address)).to.equal(0);
    });

    it("should transfer correctly with tax disabled", async function () {
      await contract.connect(fakeIcoAddress).mint(fakeIcoAddress.address, 100);
      await contract.connect(fakeIcoAddress).transfer(acc1.address, 100);
      expect(await contract.balanceOf(acc1.address)).to.equal(100);
      expect(await contract.balanceOf(fakeIcoAddress.address)).to.equal(0);
    });

    it("should transfer correctly with tax enabled", async function () {
      await contract.connect(fakeIcoAddress).mint(fakeIcoAddress.address, 100);
      await contract.enableTax();
      await contract.connect(fakeIcoAddress).transfer(acc1.address, 100);
      expect(await contract.balanceOf(acc1.address)).to.equal(98);
      expect(await contract.balanceOf(treasury.address)).to.equal(2);
    });
  });
});

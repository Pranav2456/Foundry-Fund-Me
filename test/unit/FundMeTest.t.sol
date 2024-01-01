// SPDX License-Identifier : MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe; // This is the instance of the FundMe contract that will be used in the tests

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether; // This is the starting balance of the USER.
    uint256 constant GAS_PRICE = 1;

     function setUp() external {
        // fundMe = new FundMe(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
       DeployFundMe deployFundMe = new DeployFundMe(); // This is the instance of the DeployFundMe contract that will be used in the tests. 
       fundMe = deployFundMe.run(); // here we are calling the run() function from the DeployFundMe contract.
        vm.deal(USER, STARTING_BALANCE); // This is the function that will send 10 ether to the USER address.
    } // This function is called before each test function. It creates a new instance of the FundMe contract.

      function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // This command tells the VM to expect a revert.
        fundMe.fund();
    } // This function checks whether the fund() function in the contract reverts when the user does not send enough ETH.

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next TX will be sent by USER.
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER); // This will return the value of the amount funded by the USER.
        assertEq(amountFunded, SEND_VALUE); 
    } // This function checks whether the fund() function in the contract updates the amount funded by the user.

    function testAddsFunderToArrayOfFunders() public{
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    } // This function checks whether the fund() function in the contract adds the funder to the array of funders.

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    } // This function checks whether the withdraw() function in the contract reverts when the msg.sender is not the owner.

    function testWithDrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        //uint256 gasStart = gasleft();
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //uint256 gasEnd = gasleft();
        //uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        //console.log("Gas used: ", gasUsed);
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    } // This function checks whether the withdraw() function in the contract works when there is only one funder.

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank
            //vm.deal
            hoax(address(i), SEND_VALUE); // hoax does the functions of both vm.prank and vm.deal, so it is more efficient.
            fundMe.fund{value: SEND_VALUE}();
            // fund the fundMe
        } // This loop will fund the FundMe contract with 10 different addresses.

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank(); // Anything in between startPrank and stopPrank will be pretended to be sent by the address that is passed to startPrank.
    
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    } // This function checks whether the withdraw() function in the contract works when there are multiple funders.

      function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank
            //vm.deal
            hoax(address(i), SEND_VALUE); // hoax does the functions of both vm.prank and vm.deal, so it is more efficient.
            fundMe.fund{value: SEND_VALUE}();
            // fund the fundMe
        } // This loop will fund the FundMe contract with 10 different addresses.

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank(); // Anything in between startPrank and stopPrank will be pretended to be sent by the address that is passed to startPrank.
    
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    } // This function checks whether the withdraw() function in the contract works when there are multiple funders.


     function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(),5e18);
     } // This checks whether the minimum USD condition in the fund() function in the FundMe contract is correct.

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender); // This checks he ownership of the FundMe contract.
      } // This checks whether the owner of the FundMe contract is the msg.sender, which in this case is the FundMeTest contract.

     function testPriceFeedVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4); 
    } // this is version check of the price feed contract.
}

// What can we do to work with addresses outside our system?
// 1. Unit
// - Testing a specific part of the code
// 2. Integration
// - testing how our code works with other parts of our code.
// 3. Forked
// testing our code on a simulated real environment.
// 4. Staging
// - Testing our code on a real environment that is not production.
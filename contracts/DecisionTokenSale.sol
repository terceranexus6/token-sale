pragma solidity ^0.4.13;

import "./DecisionToken.sol";
import "./zeppelin-solidity/contracts/ownership/Claimable.sol";
import './zeppelin-solidity/contracts/token/MintableToken.sol';
import './zeppelin-solidity/contracts/math/SafeMath.sol';

/**
* Horizon State Token Sale Contract
*
* Version 0.9
*
* Author Nimo Naamani
*
* This smart contract code is Copyright 2017 Horizon State (https://Horizonstate.com)
*
* Licensed under the Apache License, version 2.0: http://www.apache.org/licenses/LICENSE-2.0
*
* @title The Decision Token Sale contract
* @author Nimo Naamani, Horizon state
* @dev A crowdsale contract with stages of tokens-per-eth based on time elapsed
* Capped by maximum number of tokens; Time constrained
*/
contract DecisionTokenSale is Claimable {
  using SafeMath for uint256;

  // Start timestamp where investments are open to the public.
  // Before this timestamp - only whitelisted addresses allowed to buy.
  uint256 public startTime;

  // End time. investments can only go up to this timestamp.
  uint256 public endTime;

  // Whitelisted and 1st day buyers receive this many tokens per ETH
  uint256 public constant earlyBirdTokenRate = 3500;

  // Day 2-8 buyers receive this many tokens per ETH
  uint256 public constant secondStageTokenRate = 3250;

  // Day 9-16 buyers receive this many tokens per ETH
  uint256 public constant thirdStageTokenRate = 3000;

  // The Decision Token that is sold with this token sale
  DecisionToken public token;

  // The address where the funds are kept
  address public wallet;

  // Holds the addresses that are whitelisted to participate in the presale.
  // Sales to these addresses are allowed before saleStart
  mapping (address => bool) whiteListedForPresale;

  /**
   * Event for token purchase logging
   * @param purchaser - Who purchased the tokens
   * @param value     - Amount of wei paid for purchase
   * @param amount    - Number of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
  event LogUserAddedToWhiteList(address indexed user);
  event LogUserUserRemovedFromWhiteList(address indexed user);

  /*
  * @dev Constructor
  * @param _wallet - The wallet where the token sale proceeds are to be stored
  */
  function DecisionTokenSale(uint256 _startTime, uint256 _endTime, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_wallet != 0x0);
    startTime = _startTime;
    endTime = _endTime;
    token = createTokenContract(_endTime);
    wallet = _wallet;
  }

  // @dev Creates the token to be sold.
  function createTokenContract(uint256 _saleEnds) internal returns (DecisionToken) {
    return new DecisionToken(_saleEnds + 10 days);
  }


  /// This is the function to use for buying tokens.
  function buyTokens() payable {
    require(msg.sender != 0x0);
    require(validPurchase(msg.sender));

    uint256 weiAmount = msg.value;

    // Calculate token amount to be created
    uint256 tokens = calculateTokenAmount(weiAmount);

    if (token.totalSupply().add(tokens) > token.tokenCap()) {
      revert();
    }

    // Add the new tokens to the beneficiary
    token.mint(msg.sender, tokens);

    // Notify that a token purchase was performed
    TokenPurchase(msg.sender, weiAmount, tokens);

    // Put the funds in the token sale wallet
    wallet.transfer(msg.value);
  }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens();
  }

  // @return true if the transaction can buy tokens
  function validPurchase(address buyer) internal constant returns (bool) {
    bool saleHasOpenedForBuyer = whiteListedForPresale[buyer] || now >= startTime;
    bool nonZeroPurchase = msg.value != 0;
    return saleHasOpenedForBuyer && !hasEnded() && nonZeroPurchase;
  }

  // The token sale prefers early birds, as per the token sale whitepaper and
  // Horizon State's Token Sale page.
  // Day 1     : 3500 tokens per Ether
  // Days 2-8  : 3250 tokens per Ether
  // Days 9-16 : 3000 tokens per Ether
  function calculateTokenAmount(uint256 weiAmount) internal constant returns (uint256) {
    if (now >= startTime + 8 days) {
      return weiAmount.mul(thirdStageTokenRate);
    }
    if (now >= startTime + 1 days) {
      return weiAmount.mul(secondStageTokenRate);
    }
    return weiAmount.mul(earlyBirdTokenRate);
  }

  /// @dev This is a utility function to help consumers figure out whether the sale
  /// has already ended.
  /// @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return token.mintingFinished() || now > endTime;
  }

  // @dev Allow the owner of this contract to whitelist a buyer.
  // Whitelisted buyers may buy in the presale, i.e before the sale starts.
  function whiteListAddress(address buyer) onlyOwner {
    whiteListedForPresale[buyer] = true;
    LogUserAddedToWhiteList(buyer);
  }

  // @dev Allow the owner of this contract to whitelist multiple buyers in batch.
  // Whitelisted buyers may buy in the presale, i.e before the sale starts.
  function addWhiteListedAddressesInBatch(address[] buyers) onlyOwner {
    require(buyers.length < 100);
    for (uint i = 0; i < buyers.length; i++) {
      whiteListAddress(buyers[i]);
    }
  }

  // @dev Allow the owner of this contract to remove a buyer from the white list.
  function removeWhiteListedAddress(address buyer) onlyOwner {
    whiteListedForPresale[buyer] = false;
  }

  // @dev Allow the owner of this contract to terminate it
  // It also transfers the token ownership.
  function destroy() onlyOwner {
    token.finishMinting();
    token.transferOwnership(msg.sender);
    selfdestruct(owner);
  }
}

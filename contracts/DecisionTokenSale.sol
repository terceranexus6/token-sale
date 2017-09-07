pragma solidity ^0.4.13;

/**
 * Horizon State PRESALE CONTRACTS
 *
 * Version 0.7
 *
 * Author Nimo Naamani
 *
 * MIT LICENSE Copyright 2016 Horizon State LTD
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 **/

 import "./DecisionToken.sol";
 import "./zeppelin-solidity/contracts/ownership/Ownable.sol";
 import './zeppelin-solidity/contracts/token/MintableToken.sol';
 import './zeppelin-solidity/contracts/math/SafeMath.sol';

/// @title The Decision Token Sale contract
/// @author Nimo Naamani, Horizon state
/// @dev A crowdsale contract with stages of tokens-per-eth based on time elapsed
/// @dev Capped by maximum number of tokens;
/// @dev Time constrained
contract DecisionTokenSale is Ownable {
  using SafeMath for uint256;

  // Sale starts at 2017-10-02T00:00:00+00:00
  uint256 public constant saleStart = 1506902400;

  // Sale ends 15 days later 2017-10-17T00:00:00+00:00
  uint256 public constant saleEnd = saleStart + 15 days;

  // Early bird buyers receive this many tokens per ETH
  uint256 public constant earlyBirdTokenRate = 3500;

  // Day 2-8 buyers receive this many tokens per ETH
  uint256 public constant secondStageTokenRate = 3250;

  // Day 9-16 buyers receive this many tokens per ETH
  uint256 public constant thirdStageTokenRate = 3000;

  // The DecisionToken that is sold with this token sale
  MintableToken public token;

  // The address where the funds are kept
  address public wallet;

  // Amount of raised money in wei
  uint256 public weiRaised;

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

  /*
  * @dev  Constructor
  * @param _wallet - The wallet where the token sale proceeds are to be stored
  */
  function DecisionTokenSale(address _wallet) {
      require(saleStart >= now);
      require(saleEnd >= saleStart);
      require(_wallet != 0x0);
      token = createTokenContract();
      wallet = _wallet;
      weiRaised = 0;
  }

  // This function just creates the new DecisionToken contract, and
  // sets its owner to this contract.
  function createTokenContract() internal returns (MintableToken) {
    return new DecisionToken(saleEnd + 7 days);
  }

  /// This is the function to use for buying tokens.
  function buyTokens() payable {
    require(msg.sender != 0x0);
    require(validPurchase(msg.sender));
    uint256 weiAmount = msg.value;

    // Calculate token amount to be created
    uint256 tokens = findTokenAmount(weiAmount);

    // Update total wei raised
    weiRaised = weiRaised.add(weiAmount);

    // Add the new tokens to the beneficiary
    token.mint(msg.sender, tokens);

    // Notify that a token purchase was performed
    TokenPurchase(msg.sender, weiAmount, tokens);

    // Put the funds in the token sale wallet
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase(address buyer) internal constant returns (bool) {
    bool withinPeriod = whiteListedForPresale[buyer] || now >= saleStart;
    bool nonZeroPurchase = msg.value != 0;
    return !hasEnded() && withinPeriod && nonZeroPurchase;
  }



  // The token sale prefers early birds, as per the token sale whitepaper and
  // Horizon State's Token Sale page.
  // Day 1     : 3500 tokens per Ether
  // Days 2-8  : 3250 tokens per Ether
  // Days 9-16 : 3000 tokens per Ether
  function findTokenAmount(uint256 weiAmount) internal constant returns (uint256) {
    if (now >= saleStart + 8 days) {
      return weiAmount.mul(thirdStageTokenRate);
    }
    if (now >= saleEnd + 1 days) {
      return weiAmount.mul(secondStageTokenRate);
    }
    return weiAmount.mul(earlyBirdTokenRate);
  }

  /// This is a utility function to help consumers figure out whether the sale
  /// has already ended.
  /// @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return token.mintingFinished() || now > saleEnd;
  }

  // @dev Allow the owner of this contract to white list a buyer. White listed
  // buyers may buy in the presale, i.e before the sale starts.
  function whiteListAddress(address buyer) onlyOwner returns (bool) {
    whiteListedForPresale[buyer] = true;
    return whiteListedForPresale[buyer];
  }

  // @dev Allow the owner of this contract to remove a buyer from the white list.
  // buyers may buy in the presale, i.e before the sale starts.
  function removeWhiteListedAddress(address buyer) onlyOwner returns (bool) {
    whiteListedForPresale[buyer] = true;
    return whiteListedForPresale[buyer];
  }
}

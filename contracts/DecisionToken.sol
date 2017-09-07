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

import "./zeppelin-solidity/contracts/token/MintableToken.sol";

/*
* @title Horizon State Token
* @dev ERC20 Decision Token (DCT)
* @author Nimo Naamani
*
* DCT Tokens have 18 decimal places. The smallest meaningful (and transferable)
* unit is therefore 0.000000000000000001 DCT. This unit is called a 'danni'.
*
* 1 DCT = 1 * 10**18 = 1000000000000000000 dannis.
*
* Maximum total DCT supply is 1 Billion.
* This is equivalent to 1000000000 * 10**18 = 1e27 dannis.
*
* DCT are mintable on demand (as they are being purchased), which means that
* 1 Billion is the maximum.
*/
contract DecisionToken is MintableToken {

  // Name to appear in ERC20 wallets
  string public constant name = "Decision Token";

  // Symbol for the Decision Token to appear in ERC20 wallets
  string public constant symbol = "DCT";

  // Version of the source contract
  string public constant version = "1.0";

  // Number of decimals for token display
  uint8 public constant decimals = 18;

  // Maximum total number of tokens ever created
  uint256 public constant tokenCap =  1000 * (10**6) * 10**uint256(decimals);

  // Initial HorizonState allocation (reserve)
  uint256 public constant tokenReserve = 400 * (10**6) * 10**uint256(decimals);

  // Release timestamp - tokens can not be transfered before this time.
  uint256 public releaseTime;

  /**
   * @dev modifier to allow actions only when the token can be released
   */
  modifier whenReleased() {
    require(now >= releaseTime);
    _;
  }


  /**
  * @dev Constructor for the DecisionToken.
  * Assign the tokenReserve to Horizon State.
  */
  function DecisionToken(uint256 _releaseTime) MintableToken() {
    require(releaseTime > now);
    owner = msg.sender;
    totalSupply = tokenReserve;
    balances[owner] = totalSupply;
    Mint(owner, totalSupply);
    releaseTime = _releaseTime;
  }

  /**
   * @dev Function to mint tokens
   * Override StandardToken to return true/false rather than throw and ad
   * a Transfer event from 0x0 to owner.
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool success) {
    if (totalSupply.add(_amount) > tokenCap) {
      return false;
    }
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, owner, _amount);
    Transfer(owner, _to, _amount);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Override StandardToken to return true/false rather than throw
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value == 0) || (allowed[msg.sender][_spender] == 0)) {
      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
    } else {
      return false;
    }
  }

  // @dev override the transfer() function to only work when released
  function transfer(address _to, uint256 _value) whenReleased returns (bool) {
    return super.transfer(_to, _value);
  }

  // @dev override the transferFrom() function to only work when released
  function transferFrom(address _from, address _to, uint256 _value) whenReleased returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}

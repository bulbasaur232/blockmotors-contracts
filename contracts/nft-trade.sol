// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./nft-sale-registration.sol";

contract CarNFT_Trade is CarNFT_SaleRegistration, IKIP17Receiver{

    /**
    * 구매자가 클레이를 지불하여 구매 요청을 보내는 함수
    */
    function reserveCar(uint _tokenId) external payable registeredForSale(_tokenId) correctState(_tokenId, Status.Registered) {
        require(!isTrading(_tokenId) || msg.sender != _transactions[_tokenId].seller , "This car is currently being traded");
        require(msg.value == _carDetails[_tokenId].price, "You must pay the correct price");
        
        /*
        (bool success, ) = payable(address(this)).call{value:msg.value}("");
        require(success, "Failed to send KLAY to Contract");
        */
    
        _transactions[_tokenId].buyer = msg.sender;
        _transactions[_tokenId].state = Status.Reserved;
        _transactions[_tokenId].timestamp = block.timestamp;
    }

    /**
    * 판매자가 NFT 판매 승인하는 함수
    */
    function confirmSelling(uint _tokenId) external onlyNFTOwner(_tokenId) registeredForSale(_tokenId) correctState(_tokenId, Status.Reserved) {
        approve(_transactions[_tokenId].buyer, _tokenId);
        _transactions[_tokenId].state = Status.Approved;
    }

    /**
    * 구매자가 최종 구매 승인하는 함수
    */
    function confirmBuying(uint _tokenId) external registeredForSale(_tokenId) correctState(_tokenId, Status.Approved) returns (bool){
        require(msg.sender == _transactions[_tokenId].buyer, "Caller is not the buyer of the car");

        // 구매 승인 기한 일주일 지나면 구매 취소
        uint nowDate = block.timestamp;
        if(nowDate >= (_transactions[_tokenId].timestamp + 1 weeks)) {
            cancelCarPurchase(_tokenId);
            return false;
        }
        else {
            _completeTransaction(_tokenId);
            return true;
        }
    }

    function _completeTransaction(uint _tokenId) private {
        _transactions[_tokenId].state = Status.Completed;
        _transactions[_tokenId].timestamp = block.timestamp;
        _prevTransactions[_tokenId].push(_transactions[_tokenId]);
        
        (bool success, ) = payable(_transactions[_tokenId].seller).call{value: _transactions[_tokenId].price}("");
        require(success, "Failed to send KLAY to buyer");
        safeTransferFrom(_transactions[_tokenId].seller, _transactions[_tokenId].buyer, _tokenId);
        
        emit transactionCompleted(block.timestamp, _tokenId, _transactions[_tokenId].seller, _transactions[_tokenId].buyer);

        _popOnSale(_tokenId);
    }

    /**
     * 판매를 취소하는 함수
     */
    function cancelCarSale(uint _tokenId) public registeredForSale(_tokenId) {
        require(msg.sender == _transactions[_tokenId].seller, "Only the seller can cancel the sale");

        _refund(_tokenId);
        _popOnSale(_tokenId);
    }

    /**
     * 구매를 취소하는 함수
     * 구매자가 호출 or 구매 승인 기한 지났을 경우 호출
     */
    function cancelCarPurchase(uint _tokenId) public {
        require(isTrading(_tokenId), "This car is not trading.");
        require(msg.sender == _transactions[_tokenId].buyer, "The caller is not the buyer.");

        _refund(_tokenId);
        _transactions[_tokenId].timestamp = _carDetails[_tokenId].registDate;
        _transactions[_tokenId].buyer = address(0);
        _transactions[_tokenId].state = Status.Registered;
    }

    /**
    * 거래 취소 시 KLAY와 NFT를 돌려주는 함수
    */
    function _refund(uint _tokenId) private {
        if(isTrading(_tokenId)){
            (bool success, ) = payable(_transactions[_tokenId].buyer).call{value: _transactions[_tokenId].price}("");
            require(success, "Failed to send KLAY to buyer");
        }
    }

    /** 
    * 차량을 판매 목록에서 제거하는 함수
    */
    function _popOnSale(uint _tokenId) private {
        require(_carsOnSale.length > 0, "No cars for sale");
        uint idx = 0;
        for(uint i = 0; i < _carsOnSale.length; i++){
            if(_carsOnSale[i] == _tokenId){
                idx = i;
                break;
            }
        }
        require(_carsOnSale[idx] == _tokenId, "This car is not for sale");

        _carsOnSale[idx] = _carsOnSale[_carsOnSale.length - 1];
        _carsOnSale.pop();

        delete _carDetails[_tokenId];
        delete _transactions[_tokenId];
    }

    
    function onKIP17Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override(IKIP17Receiver) returns (bytes4) {
        return this.onKIP17Received.selector;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(KIP17) {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "KIP17: transfer caller is not owner nor approved");
        require(_isTransferable(tokenId), "Car in trade cannot be transferred");
        _transfer(from, to, tokenId);
        remapTokenId(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(KIP17) {
        require(_isTransferable(tokenId), "Car in trade cannot be transferred");
        safeTransferFrom(from, to, tokenId, "");
        remapTokenId(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(KIP17) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "KIP17: transfer caller is not owner nor approved");
        require(_isTransferable(tokenId), "Car in trade cannot be transferred");
        _safeTransfer(from, to, tokenId, _data);
        remapTokenId(from, to, tokenId);
    }

    function _isTransferable(uint _tokenId) private view returns (bool) {
        if(_transactions[_tokenId].seller != address(0)){
            return true;
        }
        else if(address(msg.sender) == _transactions[_tokenId].buyer || _transactions[_tokenId].state == Status.Completed){
            return true;
        }
        else{
            return false;
        }
    }
    
    receive() external payable {

    }

    fallback() external payable {

    }
}
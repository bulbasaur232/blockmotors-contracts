# chainmotors-contracts
## nft-trade.sol 함수 설명

🔎 조회용 함수

| 함수 시그니처 | 반환형 | 설명 | 주의사항 |
| --- | --- | --- | --- |
| `getPrevTransactions(uint _tokenId)` | Transaction[] | 차량의 이전 판매기록들을 조회 |  |
| `getCarDetails(uint _tokenId)` | Detail | 차량의 세부정보를 조회 |  |
| `isTrading(uint _tokenId)` | bool | 차량이 거래 진행 중인지 확인 | Registered 상태에서는 false |
| `getState(uint _tokenId)` | Status(uint) | 차량이 어떤 거래 단계에 있는지 확인 | 반환형이 숫자 |

🪙 거래용 함수

| 함수 시그니처 | 이벤트 | 설명 | 주의사항 |
| --- | --- | --- | --- |
| `registerCarSale(차량세부정보)` | `registerSale` | 판매자가 판매할 차량을 등록 |  |
| `reserveCar(uint _tokenId)` | `requestBuying` | 구매자가 KLAY 전송 + 구매 요청 |  |
| `sendCar(uint _tokenId)` | `approveBuying` | 판매자가 Contract로 NFT 전송 |  |
| `confirmBuying(uint _tokenId)` | `transactionCompleted` or `cancelPurchase` | 구매자가 최종승인 → `completeTransaction()`</br>구매승인기한 초과 → `cancelCarPurchase()` | 구매승인기한은 일주일 |
| `completeTransaction(uint _tokenId)` | `transactionCompleted` | 구매자와 판매자에게 NFT와 KLAY 정산 | private으로 외부호출 불가 |
| `cancelCarSale(uint _tokenId)` | `cancelSale` | 판매자가 판매를 취소 | `sendCar()` 이후에는 호출 불가 |
| `cancelCarPurchase(uint _tokenId)` | `cancelPurchase` | 구매자가 구매를 취소 |  |

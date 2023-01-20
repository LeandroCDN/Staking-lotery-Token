// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract ILotery{
   // Costo del tiket
  uint public ticketCost; 

   // Numero actual, los numeros totales vendidos serian (actualNumber-1)
   // El actual number se le dara al proximo comprador
  uint public actualNumber = 1; 

   //Cantidad de loterias, arranca en cero
  uint public loteryCounter; 

   //total price es lo que se repartira entre los ganadores
  uint public totalPrice;
   //TotalFee es lo que puede retirar la empresa a la houseWallet
  uint public totalFee;

   //los ultimos numeros ganadores y sus address
  uint[] public winersNumbers; 
  address[] public LastAddressWiners; 

   // % que se lleva de total price cada ganador 
  uint[] public percentForWiners;
   //Cantidad de ganadores que seran premiados
  uint32 public cantOfNumbers = 3;
  
   // tiket coin es la moneda con la que se compra el voleto, la que el usuario debe aprobar
  IERC20 public ticketCoin;
   // Price coin es la moneda con la que se paga el premio,
   // en este caso, sera la misma con que se compra el voleto
  IERC20 public priceCoin;

   // Numero --> Dueño del numero (va de 1 a áctualNumber-1)
  mapping(uint => address) public numberOwner;
   // este se reinicia cada 3 compras, es de uso interno
  mapping(address=>uint) public referralsBuys;
   //total historico de las compras de sus referidos
  mapping(address=>uint) public referralsAmount;
   // dado un address te regresa quien es su referente
  mapping(address=>address) public referrer;
   //lista de vip especiales, con un sistema de referido especial
  mapping(address=>bool) public referrerSpecialList;
  mapping(address=>uint) public referrerSpecialListAmount;


  //--------- FUNCIONES IMPORTANTES para el usuario

  // funcion para comprar un tiket
  // Si no tiene referido usar la misma address de quien llama
  function buyNumber(address newReferrer) public;

  // dado un i (i < cantOfNumbers) te regresa cuanto ganara ese puesto en tiempo real
  // Ejemplo winAmount(0) te regresa cuanto podra ganar el que salga primero.
  // Esto se actualiza con cada compra de tiket.
  function winAmount(uint i) public view returns(uint)


}
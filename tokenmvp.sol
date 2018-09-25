pragma solidity ^0.4.20;

contract TokenMVP {
    /* Aqui é um array com todos os saldos */
    mapping (address => uint256) public balanceOf;

    /* Instancia o contrato com a total inicial de moeda circulante pertencente ao dono do contrato */
    function TokenMVP(
        uint256 initialSupply
        ) public {
        balanceOf[msg.sender] = initialSupply;              // Atribui o total inicial ao dono
    }

    /* Enviar tokens  */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);           // Verifica se o remetente tem saldo
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Verifica se não há overflow
        balanceOf[msg.sender] -= _value;                    // Diminui o valor do remetente
        balanceOf[_to] += _value;                           // Adiciona o valor ao destinatário
        return true;
    }
}



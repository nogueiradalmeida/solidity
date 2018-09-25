pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    // Variáveis públicas do Token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimais é fortemente sugerido por padrão, evite mudar 
    uint256 public totalSupply;

    // Cria uma tabela com todos os saldos
    mapping (address => uint256) public balanceOf;
    // Cria uma tabela com valores permitidos para cada para conjunto (dono, procurador)
    mapping (address => mapping (address => uint256)) public allowance;

    // Gera eventos públicos na blockchain que irão notificar os clientes
    event Transfer(address indexed from, address indexed to, uint256 value);        
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);    
    event Burn(address indexed from, uint256 value);

    /**
     * Função Construtor 
     *
     * Instancia o contrato com a total inicial de moeda circulante pertencente ao dono do contrato 
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Atualiza o total convertendo decimais em inteiros
        balanceOf[msg.sender] = totalSupply;                  // Atribui o total inicial ao dono
        name = tokenName;                                   // Nome do token para exibição 
        symbol = tokenSymbol;                               // Símbolo do token para exibição 
    }

    /**
     * Transferência interna, apenas este contrato pode invocar esta função
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Impede a transferência para o endereço 0x0. Use a função burn() caso seja seu desejo.
        require(_to != 0x0);
        // Garante que o sender tem o valor solicitado para transferir
        require(balanceOf[_from] >= _value);
        // Garante que não acontecerá overflow (inversão de sinal)
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Armazena a soma de saldos para verificação seguinte
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtrai o valor do remetente 
        balanceOf[_from] -= _value;
        // Adiciona o valor ao destinatário
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts são usados para análise estática do código e encontrar bugs. Se falhar, há um erro
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transferência de tokens
     *
     * Envia `_value` tokens para `_to` a partir da conta do chamador
     *
     * @param _to O endereço destinatário
     * @param _value O valor a enviar
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transferência de tokens por um terceiro/procurador 
     *
     * Envia `_value` tokens para `_to` em nome de `_from`
     *
     * @param _from o endereço do remetente
     * @param _to o endereço do destinatário
     * @param _value o valor a enviar
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Verifica se valor está dentro da alçada do procurador
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Definir valor permitido para transferência por um terceiro/procurador
     *
     * Permite que `_spender` gaste até `_value` de seus tokens 
     *
     * @param _spender O endereço autorizado a gastar
     * @param _value O valor máximo a ser gasto
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Definir valor permitido para transferência por um terceiro/procurador e chama função receiveApproval
     * (vantagem do approveAndCall em relação ao approve é fazer tudo numa transação apenas)
     *
     * Permite que `_spender` a gastar não mais que `_value` tokens em seu nome e em seguida notifica o contrato
     *
     * @param _spender O endereço autorizado a gastar
     * @param _value O valor máximo a ser gasto
     * @param _extraData informação extra para enviar para o contrato 
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destrói tokens
     *
     * Remove `_value` tokens de maneira irreversível de uma conta
     *
     * @param _value a quantidade a destruir/queimar
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Verifica se o saldo da conta possui tal valor
        balanceOf[msg.sender] -= _value;            // Subtrai o valor da conta de quem chamou a função
        totalSupply -= _value;                      // Atualiza o total de moeda circulante
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destrói tokens de uma conta
     *
     * Remove `_value` tokens de maneira irreversível de uma conta `_from`.
     *
     * @param _from o endereço da conta
     * @param _value a quantidade a destruir/queimar
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Verifica se o saldo da conta possui tal valor
        require(_value <= allowance[_from][msg.sender]);    // Verifica se o procurador tem permissão para tal valor
        balanceOf[_from] -= _value;                         // Subtrai o valor da conta 
        allowance[_from][msg.sender] -= _value;             // Subtrai o valor que o procurador tem permissão
        totalSupply -= _value;                              // Atualiza o total de moeda circulante
        emit Burn(_from, _value);
        return true;
    }
}

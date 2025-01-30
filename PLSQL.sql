CREATE OR REPLACE PROCEDURE YOUR_PROCEDURE_NAME_HERE ( p_cpf IN VARCHAR2) AS

--DECLARE

  CLOB_P       CLOB;                                                    
  REQ          UTL_HTTP.REQ;                                           
  RES          UTL_HTTP.RESP;                                          
  URL          VARCHAR2(4000) := 'YOUR_API_URL_HERE';
  BUFFER       VARCHAR2(32767);                                          
  TOKEN        VARCHAR2(4000);                                           
  CPF_PACIENTE VARCHAR2 (14) := 'CPF';                         
  CPF_SEM_FORMATACAO VARCHAR2 (11);                                    

BEGIN

  -- Configura o Wallet para comunicação HTTPS
  UTL_HTTP.set_wallet('YOUR_WALLET_HERE);

  -- Remove os caracteres indesejados do CPF
  CPF_SEM_FORMATACAO := REPLACE(REPLACE(REPLACE(CPF_PACIENTE, '.', ''), '-', ''), ' ', '');

  -- Concatena o CPF na URL da API
  URL := URL || CPF_SEM_FORMATACAO;

  -- Variável para armazenar o TOKEN
  TOKEN := YOUR_TOKEN_HERE; 

  -- Inicializa a requisição GET
  REQ := UTL_HTTP.BEGIN_REQUEST(
            url          => URL,
            method       => 'GET',
            http_version => 'HTTP/1.1');

-- Define os cabeçalhos da requisição
  UTL_HTTP.SET_HEADER(REQ, 'user-agent', 'mozilla/4.0');                 
  UTL_HTTP.SET_HEADER(REQ, 'Authorization', TOKEN);                     
  UTL_HTTP.SET_HEADER(REQ, 'content-type', 'application/json;');        
  RES := UTL_HTTP.GET_RESPONSE(REQ);                                     

  BEGIN
  LOOP
    BEGIN
      UTL_HTTP.READ_TEXT(RES, BUFFER, 32767);                            
      CLOB_P := CLOB_P || TO_CLOB(BUFFER);                               
    EXCEPTION
      WHEN UTL_HTTP.END_OF_BODY THEN
        EXIT;                                                            
    END;
  END LOOP;
  UTL_HTTP.END_RESPONSE(RES);                                            
  END;


    
MERGE INTO YOUR_TABLE_TO_INSERT_HERE FAH
USING (SELECT CPF_PACIENTE AS CPF FROM DUAL) SRC
  ON (FAH.CPF = SRC.CPF)
WHEN MATCHED THEN
  UPDATE SET
    JSON_DATA = CLOB_P,
    DATA_INSERCAO = SYSDATE
WHEN NOT MATCHED THEN
  INSERT (CPF, JSON_DATA, DATA_INSERCAO)
  VALUES (CPF_PACIENTE, CLOB_P, SYSDATE);


  COMMIT;

  DBMS_OUTPUT.PUT_LINE('JSON armazenado com sucesso para o CPF: ' || CPF_PACIENTE);

EXCEPTION
  WHEN OTHERS THEN
   
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Erro ao processar o JSON: ' || SQLERRM);


END;

# 📞 URA para Provedores de Internet com Asterisk e Python  

Este projeto implementa uma **URA (Unidade de Resposta Audível)** para provedores de internet utilizando **Asterisk** e **Python**. A solução automatiza o atendimento, permitindo consultas de clientes, verificação de débitos e direcionamento eficiente para os setores responsáveis.  

---

## 🚀 Funcionalidades  

✔ **Atendimento automático via URA**  
✔ **Consulta de clientes pelo CPF**  
✔ **Verificação de débitos e desbloqueio por confiança**  
✔ **Encaminhamento para suporte, financeiro ou atendente**  

---

## 🔧 Como funciona?  

1. O cliente liga para o número **2222**.  
2. O sistema solicita o **CPF** do cliente.  
3. Após a digitação do CPF, a URA faz uma **consulta via API** ao sistema do provedor de internet.  
4. Com base na consulta, o cliente pode:  
   - **Verificar débitos** e desbloquear por confiança.  
   - **Receber atendimento do setor financeiro, suporte ou falar com um atendente.**  

---

## 📞 Estrutura da URA  

Após a validação do CPF, o cliente pode escolher entre:  

### 📌 Setor Financeiro  
   - Receber a fatura por **e-mail ou SMS**  
   - **Desbloquear a conexão por confiança**  
   - Falar com um atendente  

### 📌 Suporte Técnico  
   - Encaminhamento para soluções automatizadas  
   - Direcionamento para um atendente técnico  

### 📌 Atendimento Direto  
   - Transferência para a **fila de atendentes** no container **033**  

📌 **Se o cliente optar pelo desbloqueio por confiança**, o **Asterisk** realiza um **POST via AGI** para liberar a conexão no sistema e gerar uma ocorrência, fornecendo um número de protocolo ao cliente.  

📌 **Caso prefira falar com um atendente**, a ligação será direcionada para a **fila de atendimento**.  

---

## 📡 Endpoints da API utilizados  

### 🔹 Consulta de cliente pelo CPF  
   
   GET https://suportetsmx.sgp.net.br/api/ura/clientes/

### 🔹Verificação de débitos

   GET https://suportetsmx.sgp.net.br/api/ura/titulos
   
### 🔹Desbloqueio por confiança

   POST https://suportetsmx.sgp.net.br/api/ura/liberacaopromessa

---

## 🛠 Tecnologias utilizadas  

- **Asterisk** 📞  
- **Python** 🐍  
- **Integração com API REST** 🌐  

---

## 🛠 Instalação e Configuração  

1. Clone este repositório:  
   ```sh
   git clone https://github.com/Wellyngton-Matheus/ura-provedor.git

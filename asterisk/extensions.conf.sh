
; ATIVIDADE AGI
[projeto]
exten => 2222,1,Answer()
        same => n,Verbose(1, "Iniciando atendimento na URA")
        same => n,Set(TENTATIVAS=0)  ; Inicializa contador de tentativas
        same => n(start),Espeak("Por favor, digite o seu CPF",any)
        same => n,Read(CPF,,13)  ; Aguarda até 13 segundos pela entrada do CPF
        same => n,Verbose(1, "Usuário digitou CPF: ${CPF}")

        ; Se o CPF estiver em branco, aumenta a tentativa e verifica
        same => n,GotoIf($["${CPF}"=""]?erro)

        same => n(consulta),Verbose(1, "Consultando CPF: ${CPF}")
        same => n,AGI(consultasgp.py,${CPF})  ; Chama o script AGI
        same => n,Verbose(1, "Aguardando resposta do AGI...")

        same => n,Set(CPF_RESULT=${CPF_RESULT})
        same => n,Set(NOME_CLIENTE=${CLIENTE_NOME})
        same => n,Set(CONTRATO_VALOR_ABERTO=${CONTRATO_VALOR_ABERTO})
        same => n,Set(CLIENTE_CONTRATO=${CLIENTE_CONTRATO})
        same => n,Verbose(1, "Resultado da consulta: ${CPF_RESULT}")
        same => n,Verbose(1, "Nome do Cliente: ${NOME_CLIENTE}")
        same => n,Verbose(1, "Contrato ID: ${CLIENTE_CONTRATO}")
        same => n,Verbose(1, "Valor em aberto: ${CONTRATO_VALOR_ABERTO}")

        ; Se o CPF foi encontrado, segue o atendimento
        same => n,GotoIf($["${CPF_RESULT}"="OK"]?sucesso:falha)

same => n(sucesso),Verbose(1, "CPF localizado, continuando atendimento")
        same => n,Espeak("Olá. ${NOME_CLIENTE}, Vamos iniciar o seu atendimento ",any)
        same => n,Espeak("Você deseja falar com o Financeiro. Tecle 1",any)
        same => n,Espeak("Falar com o Suporte. Tecle 2",any)
        same => n,Espeak("Ou deseja falar com um atendente. Tecle 3",any)
        same => n,WaitExten(6)  ; Aguarda o usuário digitar uma opção

; Captura a escolha do usuário e direciona para o contexto correto
exten => 1,1,Goto(ura-financeiro,s,1)
exten => 2,1,Goto(ura-suporte,s,1)
exten => 3,1,Goto(ura-atendente,s,1)

same => n(falha),Verbose(1, "CPF nao encontrado no sistema.")
        same => n,Set(TENTATIVAS=$[${TENTATIVAS} + 1])  ; Aumenta a contagem de tentativas
        same => n,GotoIf($[${TENTATIVAS} >= 3]?tentativas_excedidas)  ; Se >=3, encerra
        same => n,Espeak("CPF invalido. Tente novamente.",any)
        same => n,Goto(start)  ; Volta para pedir o CPF

same => n(erro),Verbose(1, "Erro: Usuario nao digitou um CPF valido.")
        same => n,Set(TENTATIVAS=$[${TENTATIVAS} + 1])  ; Aumenta a contagem de tentativas
        same => n,GotoIf($[${TENTATIVAS} >= 3]?tentativas_excedidas)  ; Se >=3, encerra
        same => n,Espeak("CPF inválido. Por favor, tente novamente.",any)
        same => n,Goto(start)  ; Volta para pedir o CPF

same => n(tentativas_excedidas),Verbose(1, "Tentativas excedidas, encerrando chamada.")
        same => n,Espeak("Número máximo de tentativas atingido. Encerrando atendimento.",any)
        same => n,Hangup()

; URA FINANCEIRO

[ura-financeiro]
exten => s,1,Verbose(1, "Entrando na URA Financeiro")
        same => n,GotoIf($["${CONTRATO_VALOR_ABERTO}" = "0"]?sem_debitos:verifica_debitos)

same => n(verifica_debitos),ExecIf($["${CONTRATO_VALOR_ABERTO}" != "0"]?Espeak("Verificamos que você possui parcelas em aberto no valor de ${CONTRATO_VALOR_ABERTO} reais.",any))
        same => n,Espeak("Para receber a fatura por e-mail e SMS, tecle 1.",any)
        same => n,ExecIf($["${CONTRATO_VALOR_ABERTO}" != "0"]?Espeak("Para informar pagamento ou solicitar liberação por confiança, tecle 2.",any))
        same => n,Espeak("Falar com o Atendimento, tecle 3.",any)
        same => n,WaitExten(6)
        same => n,Hangup()

same => n(sem_debitos),Verbose(1, "Cliente não possui faturas em aberto")
        same => n,Espeak("Identificamos que você não possui faturas em aberto.",any)
        same => n,Espeak("Caso deseje falar com um atendente, tecle 3.",any)
        same => n,WaitExten(6)
        same => n,Hangup()

; Captura a escolha do usuário
exten => 3,1,Verbose(1, "Cliente escolheu falar com um atendente")
        same => n,Goto(ura-atendente,s,1)

; O cliente escolheu receber a fatura por e-mail e SMS
exten => 1,1,Verbose(1, "Cliente solicitou envio de fatura por e-mail e SMS")
        same => n,Espeak("Sua fatura foi enviada para o seu e-mail e SMS cadastrado.",any)
        same => n,Hangup()

; O cliente escolheu informar pagamento ou solicitar liberação por confiança

exten => 2,1,Verbose(1, "Cliente solicitou pagamento ou liberação por confiança")
        same => n,AGI(consultasgp.py,${CPF},LIBERAR)  ; Passando "LIBERAR" como argumento
        same => n,Wait(3)  ; Aguarda resposta da API

        ; Captura os valores retornados pelo AGI
        same => n,Set(LIBERACAO_CONF=${LIBERACAO_CONF})
        same => n,Set(LIBERACAO_PROTOCOLO=${LIBERACAO_PROTOCOLO})
        same => n,Verbose(1, "Resultado da liberação: ${LIBERACAO_CONF}")
        same => n,Verbose(1, "Protocolo gerado: ${LIBERACAO_PROTOCOLO}")

        ; Verifica se a liberação foi bem-sucedida
        same => n,GotoIf($["${LIBERACAO_CONF}" = "OK"]?liberado:erro_liberacao)

same => n(liberado),Verbose(1, "Liberação realizada com sucesso!")
        same => n,Espeak("Sua solicitação foi realizada com sucesso. O protocolo gerado: ",any)
        same => n,SayDigits(${LIBERACAO_PROTOCOLO})
        same => n,Hangup()

same => n(erro_liberacao),Verbose(1, "Falha ao liberar contrato")
        same => n,Espeak("Não foi possível realizar a solicitação. Entre em contato com o atendimento.",any)
        same => n,Hangup()

; URA SUPORTE - REDIRECIONA APENAS PARA A FILA ATENDENTE
[ura-suporte]
exten => s,1,Verbose(1, "Entrando na URA Suporte")
        same => n,Espeak("Bem-vindo ao suporte técnico. Aguarde um momento enquanto conectamos você com um atendente.",any)
        same => n,Goto(ura-atendente,s,1)  ; Redireciona a chamada para a fila de atendimento

; URA DE ATENDIMENTO DIRECIONADA AO TRONCO 033
[ura-atendente]
exten => s,1,Verbose(1, "Encaminhando chamada para a fila de atendentes")
        same => n,Set(QUEUETIMEOUT=15)  ; Tempo máximo na fila antes de reavaliar
        same => n,Queue(atendente,tT,${QUEUETIMEOUT})  ; Enfileira a chamada
        same => n,Verbose(1, "Status da Fila: ${QUEUESTATUS}")  ; Log do status da fila
        same => n,GotoIf($["${QUEUESTATUS}"="FULL"]?fila_cheia)
        same => n,GotoIf($["${QUEUESTATUS}"="TIMEOUT"]?fila_timeout)
        same => n,GotoIf($["${QUEUESTATUS}"="JOINEMPTY"]?sem_agentes)
        same => n,GotoIf($["${QUEUESTATUS}"="LEAVEEMPTY"]?sem_agentes)
        same => n,Goto(s,1)  ; Retorna ao início da fila para tentar novamente

same => n(fila_cheia),Verbose(1, "Fila cheia, informando cliente")
        same => n,Espeak("Nossa central está com todas as linhas ocupadas no momento. Por favor, aguarde.",any)
        same => n,Goto(s,1)  ; Mantém na fila

same => n(fila_timeout),Verbose(1, "Tempo de espera excedido, mantendo na fila")
        same => n,Espeak("Ainda não conseguimos atendimento. Continuamos tentando, por favor aguarde.",any)
        same => n,Goto(s,1)  ; Mantém na fila

same => n(sem_agentes),Verbose(1, "Sem atendentes disponíveis, mantendo na fila")
        same => n,Espeak("Nenhum atendente está disponível no momento. Estamos tentando reconectar.",any)
        same => n,Goto(s,1)  ; Mantém na fila


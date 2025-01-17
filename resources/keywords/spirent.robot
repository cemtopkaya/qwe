*** Variables ***
${SPIRENT_TEST_ID}    %{TEST_ID}
${SPIRENT_SERVER_NAME}    %{spirent_ts_name}
# Spirent ilgili testi koşturduğunda bir ID değeri üretir. Bu değer ile test sonuçlarını Spirent üstünde çekeriz.
${SPIRENT_RUNNING_TEST_ID}
# Testin koşturulacağı ve çekirdek şebekenin kurulu olduğu sunucu adresi
${ALLINONE_IP}    %{allinone_ip}
# Bu değişken AMF'in IP'si olup PUBLIC_IP olarak da geçer
${AMF_IP}    %{public_ip}
# Bu değişken UPF'in N6 bacağı internete çıktığı için N6_IP olarak da geçer
${UPF_IP}    %{n6_ip}

*** Settings ***
Library    Process
Library    OperatingSystem
Library    common/CommonOperations.py
Library    spirent.SpirentManager    WITH NAME    spirentManager
Library    TestConfigOperations    test_name=${SPIRENT_TEST_ID}    ts_name=${SPIRENT_SERVER_NAME}    WITH NAME    testConfig

*** Keywords ***
Is Spirent Ready
    [Documentation]    Spirent lisanslarından boşta olanı var mı?
    [Arguments]    ${_spirent_server_name}
    ${testServer}=    spirentManager.Get Test Server Or Exit    ${_spirent_server_name}
    Log To Console    message=\n$Spirent Test Servers: ${testServer}\n
    ${state}=    Set Variable If    '${testServer["state"]}' == 'READY'    True    False
    Log To Console    message=\n${_spirent_server_name} Named Spirent Test Server's state is: ${state}\n
    Return From Keyword    ${state}

Update Test Session    
    [Documentation]    Spirent üzerinde Test Oturum bilgilerini güncelleyeceğiz.
    [Arguments]    ${_spirent_server_name}    ${_test_name}    ${_h_mnc}    ${_h_mcc}    ${_amf_ip}    ${_upf_ip}
    # Test Parametrelerinden    
    ${test_params}=    testConfig.Get Test Params By Test Name    ${_test_name}
    Log To Console    ${test_params}
    ${test_id}=    Set Variable    ${test_params['test_id']}
    ${test_duration}=    Set Variable    ${test_params['test_duration']}
    ${perm_key}=    Set Variable    ${test_params['perm_key']}
    ${op_key}=    Set Variable    ${test_params['op_key']}
    ${msin}=    Set Variable    ${test_params['msin']}
    # Spirent özelliklerinden
    ${spirent_ts_params}=    testConfig.Get Spirent Ts Params By Test Name    ${_spirent_server_name}
    Log To Console    ${spirent_ts_params}
    ${spirent_ts_name}=    Set Variable    ${spirent_ts_params['ts_name']}
    ${spirent_gnb_ip}=    Set Variable    ${spirent_ts_params['spirent_gnb_ip']}
    ${spirent_dn_ip}=    Set Variable    ${spirent_ts_params['spirent_dn_ip']}
    ${spirent_dn_interface}=    Set Variable    ${spirent_ts_params['spirent_dn_interface']}
    ${spirent_gnb_interface}=    Set Variable    ${spirent_ts_params['spirent_gnb_interface']}
    # Spirent üstünden ts_name ile Test Sunucunun ID değerini çekiyoruz
    ${spirentTestServer}=    spirentManager.Get Test Server Or Exit    ${spirent_ts_name}
    ${spirent_ts_id}=    Set Variable    ${spirentTestServer['id']}
    # 
    ${spirent_library_id}=    spirentManager.Get Library Id By Spirent User Or Exit
    ${lib_id}=    Set Variable    ${spirent_library_id}
    # 
    ${ue_id}    Catenate    ${_h_mnc}    ${_h_mcc}    ${msin}
    ${data} =    spirentManager.Update Test Server Session Or Exit    ${test_id}    ${_amf_ip}    ${_upf_ip}  
    ...    ${test_duration}    ${spirent_ts_name}    ${spirent_ts_id}    ${spirent_gnb_ip}    ${spirent_dn_ip}    ${spirent_dn_interface}    ${spirent_gnb_interface}  
    ...    ${h_mnc}    ${h_mcc}    ${perm_key}    ${op_key}    ${msin}
    ${result} =    Run Keyword And Return Status    Should Be Equal As Strings    "${data['result']}"    "Test Modified"
    Return From Keyword    ${result}
    # Should Be Equal As Strings    "${data['result']}"    == "Test Modified"
    # spirent.SpirentManager.Run Test Or Exit    spirent_lib_id=${lib_id}    test_name=${_test_name} 

Run Test
    [Documentation]    Spirent üzerinde testin koşulmasını başlat
    [Arguments]    ${_test_id}    
    ${lib_id}=    spirentManager.Get Library Id By Spirent User Or Exit
    ${spirent_running_test_id}=    spirentManager.Run Test On Spirent    ${lib_id}    ${_test_id}
    Log To Console    Koşan Test ID:    ${spirent_running_test_id}    console=yes
    Return From Keyword    ${spirent_running_test_id}

Check Status Until Test Is Completed
    [Documentation]    Spirent üzerinde koşulan testin tamamlanıncaya kadar beklenmesi gerekir. 
    ...    Test tamamlanınca TEST STATUS bilgisi dönülür
    ...    Testin 30 dakika süreceği düşünülerek testin başlangıcından itibaren 20 saniye aralıklarla
    ...    testin durumu kontrol edilir. Eğer test COMPLETE veya COMPLETE_ERROR durumuyla tamamlanmışsa
    ...    testin durumu geri dönülür.
    ...    30 Dakika sonunda hala durumu COMPLETE haricinde bir değerdeyse o değerle dönülür.
    [Arguments]    ${spirent_running_test_id}
    ${test_start_time}=    Evaluate    time.time()
    ${limit_minutes}=    Set Variable    30
    ${current_time}=    Evaluate    time.time()
    ${test_stop_time}=    Evaluate    ${test_start_time} + ${limit_minutes * 60}
    WHILE    ${current_time} < ${test_stop_time}
        ${current_time}=    Evaluate    time.time()
        ${test_status}=    spirentManager.Get Test Status    ${spirent_running_test_id}
        IF    "${test_status['testStateOrStep']}" == "COMPLETE"    BREAK
        IF    "${test_status['testStateOrStep']}" == "COMPLETE_ERROR"    BREAK
        Log    ${test_status['testStateOrStep']}
        Sleep    5s
    END
    Return From Keyword    ${test_status}

Copy Test Result Files From Spirent
    [Documentation]    Spirent tarafında üretilmiş dosyaları hedef sunucuya yükler
    [Arguments]    ${_spirent_running_test_id}
    # ${copy_result}=    spirentManager.Copy Test Outpus From Spirent    ${_spirent_running_test_id}
    Log    Çalıştım

#    [Arguments]    ${description}
    # ${description}=    Set Variable    [ PASS if (Ng Setup Requests 1) ] pass if yerine testin adımlarını tek tek alıp değerlendirmesi lazım
    # ${description}=    Get Environment Variable    ${COMMENT}
    # ${start_index}=    Evaluate    "${description}".find("(")
    # ${end_index}=    Evaluate    "${description}".find(")")
    # ${extracted_text}=    Evaluate    "${description}"[${start_index+1}:${end_index}]
    # Log    Extracted Text: ${extracted_text}
    # Return From Keyword    ${extracted_text}

    # ${result}=    Run Process    ansible-playbook    playbooks/KT_CN_001.yml
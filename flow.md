## Generic flow
````mermaid
graph TD
    start([RESET])
    goapp([Activate application])
    goboot([Activate bootloader])
    bootkey1{{bootkey match inverted?}}
    bootkey2{{bootkey match on start?}}
    wait(Set bootkey and wait some time)
    clrbootkey[Clear bootkey]
    setclock[Setup RCC]
    checkpin(Setup and check pin)
    setregs[Setup MSP and VTOR]
    csverify(Verify application signature)
    setinvbootkey[Set inverted bootkey]

    start-->bootkey1
    bootkey1--Yes-->setregs
    setregs-->goapp
    bootkey1-->wait
    wait-->clrbootkey
    clrbootkey-->setclock
    wait-.hardware reset.->start
    setclock-->bootkey2
    bootkey2--Yes-->goboot
    bootkey2-->checkpin
    checkpin--Pin active-->goboot
    checkpin-->csverify
    csverify--Not match-->goboot
    csverify-->setinvbootkey
    setinvbootkey-.NVIC reset.->start
````
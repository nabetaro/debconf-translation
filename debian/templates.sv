Template: debconf/frontend
Type: select
Choices: Slang, Text, Editor, Dialog, Noninteractive
Choices-sv: Slang, Text, Textbehandlare, Dialog, Ickeinteraktiv
Default: Slang
Description: What interface should be used for configuring packages?
 Packages that use debconf for configuration share a common look and feel.
 You can select the type of user interface they use. 
 .
 The slang frontend provides a colorful, full-screen, character based
 windowing interface, while the text frontend uses a more traditional plain
 text interface. The editor frontend lets you configure things using your
 favorite text editor. The noninteractive frontend never asks you any
 questions. The dialog frontend is a primative frontend that is being
 phased out. 
Description-sv: Vilket gränssnitt skall användas för att konfigurera paket?
 Paket som använder debconf för konfiguration delar ett gemensamt utseende
 och känsla. Du kan välja vilken sorts användargränssnitt de använder. 
 .
 Slang-skalet ger en färgfullt, helskärms, teckenbaserat fönstergränssnitt,
 medan textskalet använder ett mer traditionellt gränssnitt med ren text.
 Textbehandlarskalet låter dig konfigurera saker med din
 favorittextbehandlare. Det ickeinteraktiva skalet frågar dig aldrig
 någonting. Dialogskalet är ett primitivt skal som är på väg att fasas
 ut.

Template: debconf/priority
Type: select
Choices: critical, high, medium, low
Choices-sv: kritisk, hög, medium, låg
Default: medium
Description: Ignore questions with a priority less than..
 Packages that use debconf for configuration prioritize the questions they
 might ask you. Only questions with a certain priority or higher are
 actually shown to you; all less important questions are skipped. 
 .
 You can select the lowest priority of question you want to see:  
   - `critical' is for items that will probably break the system
     without user intervention.
   - `high' is for items that don't have reasonable defaults.
   - `medium' is for normal items that have reasonable defaults.
   - `low' is for trivial items that have defaults that will work in the
     vast majority of cases.
 .
 For example, this question is of medium priority, and if your priority
 were  already `high' or `critical', you wouldn't see this question. 
 .
 If you are new to the Debian GNU/Linux system choose `critical' now, so
 you only see the most important questions. 
Description-sv: Ignorera frågor med en prioritet lägre än..
 Paket som använder debconf för konfigurering prioriterar de frågor de kan
 fråga dig. Endast frågor med en viss prioritet eller högre visas faktiskt
 för dig; alla mindra viktiga frågor hoppas över. 
 .
 Du kan välja den lägsta prioritet vars frågor du vill se: 
   - "kritisk" är för frågor som sannolikt kan ge stora problem för
     systemet om användaren inte intervenerar.
   - "hög" är för frågor som saknar rimliga förval.
   - "medium" är för vanliga frågor som har rimliga förval.
   - "låg" är för triviala frågor som har förval som fungerar i de
     allra flesta fall.
 .
 Som ett exempel har denna fråga prioriteten "medium", och om din prioritet
 redan vore "hög" eller "kritisk" skulle du inte se denna fråga. 
 .
 Om du är nybörjade på Debian GNU/Linux-systemet, välj "kritisk" nu, så får
 du bara se de viktigaste frågorna. 

Template: debconf/showold
Type: boolean
Default: false
Description: Show all old questions again and again?
 Debconf normally only asks you any given question once. Then it remembers
 your answer and never asks you that question again. If you prefer, debconf
 can ask you questions over and over again, each time you upgrade or
 reinstall a package that asks them. 
 .
 Note that no matter what you choose here, you can see old questions again
 by using the dpkg-reconfigure program. 
Description-sv: Visa alla gamla frågor igen och igen?
 Debconf frågar normalt sett bara varje given fråga en gång, och kommer
 sedan ihåg dina svar så att frågan inte behöver ställas igen. Om du så
 önskar, kan debconf ställa frågor åter och åter igen, varje gång du
 uppgraderar eller ominstallerar ett paket som ställer dem. 
 .
 Observera: oavsett vad du väljer här kan du se gamla frågor igen genom att
 använda programmet dpkg-reconfigure. 

Template: debconf/switch-to-slang
Type: boolean
Default: true
Description: Switch to the new, full-featured slang frontend?
 You are currently using debconf's dialog frontend. This frontend has been
 superceded by a new frontend, called the slang frontend, that does
 everything the dialog frontend does and more. It lets you see and answer
 multiple questions at a time, and is generally more flexable and pleasant
 to use. If you'd like, you can switch to that frontend now. 
Description-sv: Byta till det nya, fullt fungerade slangskalet?
 Du använder just nu debconfs dialogskal. Detta skal har ersatts med ett
 nytt skal, kallat slangskalet, som gör allting dialogskalet gör, och mer
 därtill. Det låter dig se och besvara flera frågor samtidigt, och är
 oftast mer flexibelt och trevligt att använda. Om du så önskar kan du byta
 till det skalet nu. 

Template: debconf/helpvisible
Type: boolean
Default: true
Description: Should debconf display extended help for questions?
 Debconf can display extended help for questions. Some frontends allow this
 display to be turned off, which may make them run a bit faster, or be less
 cluttered. This is mostly useful for experts. 
Description-sv: Skall debconf visa utökad hjälp för frågor?
 Debconf kan visa utökad hjälp för frågor. Vissa skal gör det möjligt att
 stänga av denna visning, vilket kan göra att de körs snabbare, eller inte
 är lika "skräpiga". Detta är huvudsakligen användbart för experter. 

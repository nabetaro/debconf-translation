Template: debconf/frontend
Type: select
Choices: Dialog, Readline, Gnome, Editor, Noninteractive
Choices-sv: Dialog, Readline, Gnome, Textredigerare, Icke-interaktiv
Default: Dialog
Description: What interface should be used for configuring packages?
 Packages that use debconf for configuration share a common look and feel.
 You can select the type of user interface they use.
 .
 The dialog frontend is a full-screen, character based interface, while the
 readline frontend uses a more traditional plain text interface, and the gnome
 frontend is a modern X interface. The editor frontend lets you configure
 things using your favorite text editor. The noninteractive frontend never
 asks you any questions.
Description-sv: Vilket skal skall användas för att konfigurera paket?
 Paket som använder debconf för konfigurering delar ett gemensamt utseende.
 Du kan välja vilken sorts användargränssnitt de skall använda.
 .
 Dialogskalet är ett textbaserat fullskärmsgränssnitt, medan readline-skalet
 använder ett mer traditionellt ren text-gränssnitt, och Gnome-skalet är ett
 modernt X-gränssnitt. Textredigeringsskalet låter dig konfigurera saker med
 ditt favorittextredigeringsprogram. Det icke-interaktiva skalet ställer
 aldrig några frågor till dig.

Template: debconf/priority
Type: select
Choices: critical, high, medium, low
Choices-sv: kritisk, hög, medium, låg
Default: medium
Description: Ignore questions with a priority less than..
 Packages that use debconf for configuration prioritize the questions they
 might ask you. Only questions with a certain priority or higher are actually
 shown to you; all less important questions are skipped.
 .
 You can select the lowest priority of question you want to see: 
   - 'critical' is for items that will probably break the system
     without user intervention.
   - 'high' is for items that don't have reasonable defaults.
   - 'medium' is for normal items that have reasonable defaults.
   - 'low' is for trivial items that have defaults that will work in the
     vast majority of cases.
 .
 For example, this question is of medium priority, and if your priority were 
 already 'high' or 'critical', you wouldn't see this question.
 .
 If you are new to the Debian GNU/Linux system choose 'critical' now,
 so you only see the most important questions.
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
 can ask you questions over and over again, each time you upgrade or reinstall
 a package that asks them.
 .
 Note that no matter what you choose here, you can see old questions again by
 using the dpkg-reconfigure program.
Description-sv: Visa alla gamla frågor igen och åter igen?
 Debconf ställer normalt sett bara varje given fråga en gång och kommer
 sedan ihåg dina svar så att frågan inte behöver ställas igen. Om du så
 önskar kan debconf ställa frågor om och om igen, varje gång du
 uppgraderar eller ominstallerar ett paket som ställer dem. 
 .
 Observera att oavsett vad du väljer här kan du se gamla frågor igen genom att
 använda programmet dpkg-reconfigure. 

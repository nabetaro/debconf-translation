Template: debconf/showold
Type: boolean
Description: Show all old questions again and again?
 Debconf normally only asks you any given question once. Then it remembers
 your answer and never asks you that question again. If you prefer,
 debconf can ask you questions over and over again, each time you upgrade
 or reinstall a package that asks them.
 .
 Note that no matter what you choose here, you can see old questions again
 by using the dpkg-reconfigure program.
Description-nl: Alle oude vragen blijven herhalen?
 Debconf vraagt u normaal gesproken alle vragen slechts een maal. Daarna
 onthoudt het uw antwoord en vraagt u die vraag niet meer. Als u dat
 liever heeft, kan debconf u bij elke upgrade of herinstallatie van een
 pakket de vragen opnieuw stellen.
 .
 Los van wat u hier antwoord, kunt u oude vragen altijd opnieuw zien
 door het dpkg-reconfigure programma te gebruiken.

Template: debconf/switch-to-slang
Type: boolean
Description: Switch to the new, full-featured slang frontend?
 You are currently using debconf's dialog frontend. This frontend has been
 superceded by a new frontend, called the slang frontend, that does
 everything the dialog frontend does and more. It lets you see and answer
 multiple questions at a time, and is generally more flexable and pleasant
 to use. If you'd like, you can switch to that frontend now.
Description-nl: Overgaan naar de nieuwe, uitgebreide 'slang' schil?
 U gebruikt momenteel debconf's 'dialog' schil. Deze heeft nu een opvolger
 genaamd 'slang', die alles kan wat 'dialog' kan en meer. U kunt hiermee
 meerdere vragen tegelijk zien en beantwoorden. Verder is ze over het
 algemeen flexibeler en prettiger in gebruik. Als u wilt, kunt u nu
 overstappen op de nieuwe schil.

Template: debconf/priority
Type: select
Choices: critical, high, medium, low
Choices-nl: kritiek, hoog, gemiddeld, laag
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
Description-nl: Negeer vragen met een prioriteit lager dan..
 Pakketten die debconf gebruiken voor het instellen, prioriteren de
 vragen die ze u kunnen stellen. Alleen vragen met een bepaalde
 prioriteit of hoger worden u daadwerkelijk voorgelegd; alle minder
 belangrijke vragen worden overgeslagen.
 .
 U kunt selecteren wat de laagste prioriteit is die u wilt zien:
   - 'kritiek' is voor vragen die waarschijnlijk uw systeem onbruikbaar
     maken zonder interventie door de gebruiker
   - 'hoog' is voor vragen die onredelijke standaardwaarden hebben
   - 'gemiddeld' is voor vragen met redelijke standaardwaarden
   - 'laag' is voor triviale vragen met standaardwaarden die in bijna
     alle voorkomende gevallen werken
 .
 Deze vraag bijvoorbeeld is van gemiddelde prioriteit en als uw
 prioritering al op 'hoog' of 'kritiek' staat, dan had u deze vraag niet
 gezien.
 .
 Indien u Debian GNU/Linux voor het eerst gebruikt, kunt u het beste
 voor 'kritiek' kiezen nu. U krijgt dan alleen de meest belangrijke vragen
 te zien.

Template: debconf/frontend
Type: select
Choices: Slang, Text, Editor, Dialog, Noninteractive
Choices-nl: Slang, Text, Editor, Dialog, Noninteractive
Description: What interface should be used for configuring packages?
 Packages that use debconf for configuration share a common look and feel.
 You can select the type of user interface they use.
 .
 The slang frontend provides a colorful, full-screen, character based
 windowing interface, while the text frontend uses a more traditional plain
 text interface. The editor frontend lets you configure things using your
 favorite text editor. The noninteractive frontend never asks you any
 questions.
Description-nl: Welke interface moet gebruikt worden bij het instellen van pakketten?
 Pakketten die debconf gebruiken voor hun configuratie delen een
 gezamelijke look-and-feel. U kunt selecteren welk type interface u wilt
 gebruiken.
 .
 De 'slang' interface gebruikt een kleurrijke, volschermse,
 karaktergebaseerde interface, terwijl de 'text' interface een meer
 traditionele tekst interface gebruikt. De 'editor' interface laat u uw
 favoriete editor gebruiken om de pakketten in te stellen. De
 'noninteractive' interface stelt u in het geheel geen vragen.

Template: debconf/preconfig
Type: boolean
Description: Pre-configure packages before they are installed?
 Debconf can be used to configure packages before they are installed by
 apt. This lets you answer most questions a package would ask at the
 beginning of the install, so you do not need to be around to answer
 questions during the rest of the install.
Description-nl: Pakketten instellen voor installatie?
 Debconf kan pakketten instellen voordat ze door apt geinstalleerd
 worden. Dit zorgt er voor dat u de meeste vragen die een pakket u zou
 stellen al aan het begin van de installatie gesteld krijgt. U hoeft dan
 niet in de buurt te blijven gedurende de resterende tijd van de
 installatie.

Template: debconf/helpvisible
Type: boolean
Description: Should debconf display extended help for questions?
 Debconf can display extended help for questions. Some frontends allow
 this display to be turned off, which may make them run a bit faster, or
 be less cluttered. This is mostly useful for experts.
Description-nl: Moet debconf uitgebreide hulp tonen voor vragen?
 Debconf kan uitgebreide hulp tonen voor vragen. Sommige schillen staan
 toe dat deze functie uitgeschakeld wordt, waardoor ze iets sneller
 uitgevoerd worden of er minder opeengepakt uitzien. Dit is met name voor
 experts handig.

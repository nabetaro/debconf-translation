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

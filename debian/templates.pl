Template: debconf/priority
Type: select
Choices: critical, high, medium, low
Choices-pl: najwy¿szy, wysoki, ¶redni, niski
Default: medium
Description: Ignore questions with a priority less than..
 Packages that use debconf for configuration prioritize the questions they
 might ask you. Only questions with a certain priority or higher are actually
 shown to you; all less important questions are skipped and the defaults are
 used for them.
 .
 You can select the lowest priority of question you want to see: `low' is for
 trivial items that have defaults that will work in the vast majority of
 cases. `medium' is for normal items that have reasonable defaults.  `high'
 is for items that don't have reasonable defaults. `critical' is for items
 that will probably break the system without user intervention. For example,
 this question is of medium priority, and if your priority were already
 `high' or `critical', you wouldn't see this question.
 .
 If you are new to the Debian GNU/Linux system choose `critical' now,
 so you only see the most important questions.
Description-pl: Nie zadawaj pytañ o priorytecie ni¿szym ni¿..
 Pakiety u¿ywaj±ce do konfiguracji debconfa mog± wybraæ priorytet dla
 ka¿dego pytania. Zadawane s± tylko pytania o priorytecie równym, lub
 wy¿szym od pewnego wybranego. Wszystkie mniej wa¿ne pytania s± pomijane i
 za odpowiedzi przyjmowane s± warto¶ci domy¶lne.
 .
 Mo¿esz wybraæ najni¿szy priorytet pytañ, które chcesz zobaczyæ. `niski' to
 ma³o istotne pytania, dla których odpowiedzi domy¶lne bêd± dzia³a³y w
 wiêkszo¶ci przypadków. `¶redni' to zwyk³e pytania, które posiadaj± dobre
 odpowiedzi domy¶lne. `wysoki' odpowiada pytaniom, które nie posiadaj±
 dobrych odpowiedzi domy¶lnych. `najwy¿szy' odpowiada pytaniom, na które
 musisz udzieliæ odpowiedzi, poniewa¿ w przeciwnym wypadku system mo¿e
 przestaæ dzia³aæ poprawnie. Na przyk³ad to pytanie posiada priorytet
 `¶redni' i nie zosta³oby zadane, gdyby progowy priorytet by³ ustalony na
 `najwy¿szy' lub `wysoki'.
 .
 Je¶li jeste¶ nowym u¿ytkownikiem systemu Debian, wybierz priorytet
 `najwy¿szy', aby widzieæ tylko najwa¿niejsze pytania.

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
Description-pl: Czy zawsze zadawaæ stare pytania?
 Normalnie debconf zadaje dane pytanie tylko raz. Zapamiêtuje odpowied¼ i
 nigdy wiêcej nie zadaje tego samego pytania. Je¶li chcesz, debconf mo¿e
 zadawaæ pytania za przy ka¿dym uaktualnieniu lub reinstalacji danego
 pakietu.
 .
 Zwróæ uwagê, ¿e bez wzglêdu na odpowied¼ na to pytanie mo¿esz zobaczyæ
 dowolne pytanie jeszcze raz u¿ywaj±c programu dpkg-reconfigure.

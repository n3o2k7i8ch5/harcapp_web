import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:harcapp_web/common/base_scaffold.dart';
import 'package:harcapp_web/router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../consts.dart';

class PrivacyPolicyPage extends StatelessWidget{

  const PrivacyPolicyPage();

  @override
  Widget build(BuildContext context) => BaseScaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: BoxConstraints(maxWidth: defPageWidth),
        child: Padding(
          padding: const EdgeInsets.all(Dimen.sideMarg),
          child: ListView(
            clipBehavior: Clip.none,
            physics: BouncingScrollPhysics(),
            children: [

              SizedBox(height: 24.0),

              Row(
                children: [

                  SimpleButton.from(
                    context: context,
                    margin: EdgeInsets.zero,
                    padding: EdgeInsets.all(24.0),
                    icon: MdiIcons.arrowLeft,
                    onTap: () => context.go(pathHome)
                  ),

                  SizedBox(width: 12.0),

                  Text(
                      'Polityka prywatności',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w700,
                        color: iconEnab_(context),
                      )
                  ),
                ],
              ),

              SizedBox(height: 36.0),

              Text(
                'Polityka prywatności Aplikacji HarcApp i Strony harcapp.web.app'
                '\n\nZapewniamy naszym użytkownikom pełne poszanowanie ich prywatności oraz ochronę ich danych osobowych.',
                style: TextStyle(
                  fontSize: Dimen.textSizeBig,
                  fontWeight: FontWeight.w700,
                  color: iconEnab_(context),
                ),
                textAlign: TextAlign.justify,
              ),

              SizedBox(height: 36.0),

              Text(
                  'Dane osobowe są chronione zgodnie z rozporządzeniem Parlamentu Europejskiego i Rady (UE) 2016/679 z dnia 27 kwietnia 2016 r. w sprawie ochrony osób fizycznych w związku z przetwarzaniem danych osobowych i w sprawie swobodnego przepływu takich danych oraz uchylenia dyrektywy 95/46/WE (ogólne rozporządzenie o ochronie danych) Ustawą z dnia 10 maja 2018 r. o ochronie danych osobowych (Dz. U. 2018 poz. 1000) w sposób uniemożliwiający dostęp do nich przez osoby trzecie.'
                      '\n'
                      '\nDane są przetwarzane zgodne z ww. rozporządzeniem. Osoba fizyczna ma prawo do żądania od Administratora Danych Osobowych informacji o:'
                      '\n1. okresie przetwarzania jej danych,'
                      '\n2.dostępu do danych – ich poprawiania, zaprzestania przetwarzania (cofnięcia zgody na przetwarzanie), zmiany lub usunięcia, przenoszenia danych na warunkach wynikających z przepisów prawa i uzgodnionych z Administratorem Danych Osobowych, wniesienia ewentualnej skargi do Prezesa Urzędu Ochrony Danych Osobowych.'
                      '\n'
                      '\nAdministrator Danych Osobowych nie podejmuje decyzji, która opiera się wyłącznie na zautomatyzowanym przetwarzaniu danych osobowych. ADO nie stosuje zautomatyzowanego przetwarzania danych osobowych, które polega na wykorzystaniu danych osobowych do oceny niektórych czynników osobowych osoby fizycznej, w szczególności do analizy lub prognozy aspektów dotyczących sytuacji ekonomicznej osoby fizycznej, jej statusu, osobistych preferencji, zainteresowań, wiarygodności, zachowania, lokalizacji lub przemieszczania się.'
                      '\n'
                      '\nKażdy użytkownik, który przekazał nam swoje dane osobowe ma pełną możliwość dostępu do swoich danych w celu ich weryfikacji, modyfikacji lub też żądania usunięcia.'
                      '\n'
                      '\nTwórca aplikacji HarcApp oraz wydawca strony harcapp.web.app nie przekazuje, nie sprzedaje ani nie użycza zgromadzonych danych osobowych użytkowników osobom trzecim, chyba że dzieje się to za wyraźną zgodą lub na życzenie użytkownika albo na żądanie uprawnionych na podstawie prawa organów państwa w związku z toczącymi się postępowaniami.'
                      '\n'
                      '\nNasza strona harcapp.web.app posługuje się również tzw. plikami cookies (ciasteczka). Pliki te są zapisywane na komputerze użytkownika przez nasz serwer i dostarczają danych statystycznych o aktywności użytkownika, w celu dobrania naszej oferty do jego indywidualnych potrzeb i gustów. Użytkownik w każdej chwili może wyłączyć w swojej przeglądarce internetowej opcję przyjmowania cookies, choć musi mieć świadomość, że w niektórych przypadkach odłączenie tych plików może wpłynąć na utrudnienia w korzystaniu ze strony harcapp.web.app. Pliki cookies zapisywane na komputerze użytkownika są konieczne do:'
                      '\n- utrzymaniem sesji użytkownika,'
                      '\n- dostosowania strony harcapp.web.app do potrzeb użytkowników,'
                      '\n- tworzenia statystyk oglądalności podstron strony internetowej harcapp.web.app,'
                      '\n'
                      '\nPragniemy zwrócić Państwa uwagę, że jeżeli na stronie internetowej harcapp.web.app zamieszczamy linki prowadzące do innych, nieadministrowanych przez nas stron internetowych, to nie możemy odpowiadać ani za zawartość tychże stron, ani za stopień ochrony prywatności realizowany przez administratorów tych stron. Podejmując decyzję o przejściu na takie strony, użytkownik czyni to na własną odpowiedzialność. Zachęcamy przy okazji do zapoznania się z polityką prywatności realizowaną przez te strony, zanim użytkownik udostępni im swoje dane osobowe.'
                      '\n'
                      '\nMateriały reklamowo – promocyjne wysyłamy Klientom jedynie wówczas, gdy dotyczą one zmian na stronie harcapp.web.app i aplikacji HarcApp.'
                      '\n'
                      '\nWszelkie pytania, wnioski i sugestie odnoszące się do ochrony Państwa prywatności, w szczególności danych osobowych prosimy zgłaszać na adres harcapp@gmail.com.',
                  style: TextStyle(
                    fontSize: Dimen.textSizeBig,
                    color: iconEnab_(context),
                  ),
                  textAlign: TextAlign.justify,
              ),

              SizedBox(height: 36.0),

            ],
          ),
        ),
      ),
    ),
  );

}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Groupting';

  @override
  String get confirm => '確認';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '閉じる';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get later => 'あとで';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get retry => '再試行';

  @override
  String get settings => '設定';

  @override
  String get male => '男性';

  @override
  String get female => '女性';

  @override
  String get gender => '性別';

  @override
  String get view => '見る';

  @override
  String get loginButton => 'ログイン';

  @override
  String get registerButton => '新規登録';

  @override
  String get emailLabel => 'メールアドレス';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get emailHelper => 'ログインおよびパスワード再設定に使用します';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get passwordHint => '8文字以上';

  @override
  String get passwordConfirmLabel => 'パスワード確認';

  @override
  String get phoneLabel => '電話番号';

  @override
  String get birthDateLabel => '生年月日';

  @override
  String get birthDateHelper => '数字8桁 (例: 19950315)';

  @override
  String get registerWelcome => 'Grouptingへようこそ！\nメールアドレスで簡単に登録できます。';

  @override
  String get lockedInfo => '鍵マークの情報は登録後に変更できません';

  @override
  String get emailDuplicate => 'すでに使用されているメールアドレスです。';

  @override
  String get emailAvailable => '使用可能なメールアドレスです。';

  @override
  String get emailCheckError => 'メールアドレスの確認中にエラーが発生しました。';

  @override
  String get emailDuplicateError => 'すでに使用されているメールアドレスです。別のアドレスを使用してください。';

  @override
  String get phoneDuplicate => 'すでに使用されている電話番号です。';

  @override
  String get phoneAvailable => '使用可能な電話番号です。';

  @override
  String get phoneCheckError => '電話番号の確認中にエラーが発生しました。';

  @override
  String get phoneDuplicateError => 'すでに使用されている電話番号です。別の番号を使用してください。';

  @override
  String get verifyButton => '認証';

  @override
  String get verified => '認証済み';

  @override
  String get verifyCodeSent => '認証番号を送信しました。';

  @override
  String get verifyCodeLabel => '認証番号6桁';

  @override
  String get verifyCodeHint => '000000';

  @override
  String get verifyComplete => '電話番号の認証が完了しました。';

  @override
  String get verifyPhoneFirst => '電話番号認証を完了してください。';

  @override
  String get checkPhoneDuplicateFirst => '正しい電話番号を入力し、重複確認を完了してください。';

  @override
  String get termsAgreement => '[必須] 利用規約に同意する';

  @override
  String get privacyAgreement => '[必須] プライバシーポリシーに同意する';

  @override
  String get termsTitle => '利用規約 (EULA)';

  @override
  String get privacyTitle => 'プライバシーポリシー';

  @override
  String get alreadyHaveAccount => 'すでにアカウントをお持ちですか？ログイン';

  @override
  String get registerSuccess => '登録されました！まずはプロフィールを完成させてください。';

  @override
  String get emailRequired => 'メールアドレスを入力してください。';

  @override
  String get emailInvalid => '正しいメールアドレスの形式で入力してください。';

  @override
  String get passwordRequired => 'パスワードを入力してください。';

  @override
  String get passwordLength => 'パスワードは8文字以上である必要があります。';

  @override
  String get passwordMismatch => 'パスワードが一致しません。';

  @override
  String get passwordReEnter => 'パスワードを再度入力してください。';

  @override
  String get phoneRequired => '電話番号を入力してください。';

  @override
  String get birthDateRequired => '生年月日を入力してください。';

  @override
  String get birthDateInvalid => '生年月日は8桁である必要があります。';

  @override
  String get birthDateYearInvalid => '有効な年を入力してください。';

  @override
  String get birthDateDateInvalid => '有効な日付を入力してください。';

  @override
  String get underageError => '18歳未満の方はご利用いただけません。';

  @override
  String get genderRequired => '性別を選択してください。';

  @override
  String get termsRequired => '利用規約とプライバシーポリシーに同意してください。';

  @override
  String get fillAllRequired => 'すべての必須項目を入力してください。';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabInvite => '招待';

  @override
  String get tabMyPage => 'マイページ';

  @override
  String get tabMore => 'その他';

  @override
  String get profileCardTitleRegister => '会員登録する';

  @override
  String get profileCardTitleBasic => '基本情報を入力';

  @override
  String get profileCardTitleComplete => 'プロフィール完成';

  @override
  String get profileCardDescRegister =>
      'Grouptingサービスを利用するには、\nまず会員登録を完了してください！';

  @override
  String get profileCardDescBasic =>
      '登録時の必須情報が不足しています。\n基本情報を入力してプロフィールを完成させましょう！';

  @override
  String get profileCardDescComplete =>
      'ニックネーム、身長、自己紹介、活動地域を追加すると\nグループ作成やマッチング機能が利用できます！';

  @override
  String get profileCardSubtitleRegister => 'Grouptingを始めましょう！';

  @override
  String get profileCardSubtitleBasic => '電話番号、生年月日、性別情報が必要です！';

  @override
  String get profileCardSubtitleComplete => 'ニックネーム、身長、活動地域などを入力してください！';

  @override
  String get profileCardButtonComplete => '今すぐ完成させる';

  @override
  String get profileCardHideMsg =>
      'プロフィール完成の通知を非表示にしました。マイページからいつでも完成させることができます。';

  @override
  String get groupLoading => 'グループ情報を読み込み中...';

  @override
  String get waitPlease => 'しばらくお待ちください。';

  @override
  String get networkError => 'ネットワークエラー';

  @override
  String get networkErrorMsg => 'インターネット接続を確認して、再度お試しください。';

  @override
  String get networkCheckMsg => 'Wi-Fiまたはモバイルデータ通信を確認してください。';

  @override
  String get checkConnection => '接続を確認';

  @override
  String get dataLoadFail => 'データの読み込みに失敗しました';

  @override
  String get unknownError => '不明なエラーが発生しました。';

  @override
  String get noGroup => 'グループがありません';

  @override
  String get createGroup => 'グループ作成';

  @override
  String get createGroupDesc => '新しいグループを作って友達と一緒に楽しみましょう！';

  @override
  String get profileCompleteNeeded => 'プロフィール完成が必要です';

  @override
  String get profileCompleteNeededMsg => 'サービスを利用するにはプロフィールを完成させる必要があります。';

  @override
  String get matched => 'マッチング完了！';

  @override
  String get matching => 'マッチング中...';

  @override
  String get groupWaiting => 'グループ待機中';

  @override
  String totalMembers(Object count) {
    return 'メンバー数: $count名';
  }

  @override
  String get matchChat => 'マッチングチャット';

  @override
  String get groupChat => 'グループチャット';

  @override
  String get currentMembers => '現在のメンバー';

  @override
  String get inviteFriend => '友達招待';

  @override
  String startMatching(Object count) {
    return 'グループマッチング開始 ($count名)';
  }

  @override
  String get startMatching1on1 => '1:1マッチング開始';

  @override
  String get cancelMatching => 'マッチングキャンセル';

  @override
  String get minMemberRequired => '最低1名必要';

  @override
  String get matchSuccessTitle => 'マッチング成功！ 🎉';

  @override
  String get matchSuccessContent => 'マッチングしました！\nチャットルームで挨拶してみましょう 👋';

  @override
  String get moveToChat => 'チャットルームへ移動';

  @override
  String get receivedInvites => '届いた招待';

  @override
  String get leaveGroup => 'グループ退会';

  @override
  String get leaveGroupConfirm => '本当にグループを退会しますか？';

  @override
  String get leaveGroupSuccess => 'グループから退会しました。';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutConfirm => '本当にログアウトしますか？';

  @override
  String logoutError(Object error) {
    return 'ログアウト中にエラーが発生しました: $error';
  }

  @override
  String get filterTitle => 'マッチングフィルター設定';

  @override
  String get targetGender => '相手グループの性別';

  @override
  String get genderAny => '指定なし';

  @override
  String get genderMixed => '男女混合';

  @override
  String get targetAge => '相手グループの平均年齢';

  @override
  String get ageUnit => '歳';

  @override
  String get ageOver60 => '60歳以上';

  @override
  String get targetHeight => '相手グループの平均身長';

  @override
  String get heightUnit => 'cm';

  @override
  String get heightOver190 => '190cm以上';

  @override
  String get distanceRange => '距離範囲 (リーダー基準)';

  @override
  String get distanceUnit => 'km以内';

  @override
  String get distanceOver100 => '100km以上';

  @override
  String get applyFilter => '適用する';

  @override
  String get filterApplied => 'フィルターが適用されました。';

  @override
  String get filterApplyFail => 'フィルターの適用に失敗しました';

  @override
  String get editProfileTitle => 'プロフィール編集';

  @override
  String get photoRegisterInfo => '最大6枚の写真を登録してください。';

  @override
  String get mainPhotoInfo => '画像を長押しすると代表プロフィールに設定できます。';

  @override
  String get nicknameLabel => 'ニックネーム';

  @override
  String get nicknamePlaceholder => 'ニックネームを入力';

  @override
  String get nicknameDuplicate => 'すでに使用されているニックネームです。';

  @override
  String get nicknameAvailable => '使用可能なニックネームです。';

  @override
  String get nicknameCheckError => 'ニックネーム確認中にエラーが発生しました。';

  @override
  String get nicknameRequired => 'ニックネームを入力してください。';

  @override
  String get nicknameLengthError => 'ニックネームは2文字以上である必要があります。';

  @override
  String get heightLabel => '身長 (cm)';

  @override
  String get heightPlaceholder => '身長を入力';

  @override
  String get heightRequired => '身長を入力してください。';

  @override
  String get heightRangeError => '正しい身長を入力してください。(140-220cm)';

  @override
  String get locationLabel => '活動地域';

  @override
  String get locationPlaceholder => '地図をタップして位置を選択';

  @override
  String get locationRequired => '活動地域を選択してください。';

  @override
  String get introLabel => '自己紹介';

  @override
  String get introHelper => '200文字以内';

  @override
  String get introRequired => '自己紹介を入力してください。';

  @override
  String get introLengthError => '自己紹介は5文字以上入力してください。';

  @override
  String get immutableInfo => '変更不可の情報';

  @override
  String get idLabel => 'ID';

  @override
  String get permissionRequiredTitle => '権限設定が必要';

  @override
  String get permissionRequiredContent =>
      'プロフィール写真を登録するにはギャラリーへのアクセス権限が必要です。\n設定から権限を許可してください。';

  @override
  String get goToSettings => '設定へ移動';

  @override
  String get imageSelectError => '画像の選択中にエラーが発生しました。';

  @override
  String mainProfileSet(Object index) {
    return '$index番の画像が代表プロフィールに設定されました。';
  }

  @override
  String get mainLabel => '代表';

  @override
  String get imageUploadFail => '画像のアップロードに失敗しました。';

  @override
  String get profileUpdateSuccess => 'プロフィールが正常に更新されました。';

  @override
  String get photoRequired => '写真を最低1枚登録してください。';

  @override
  String get updateTitle => 'アップデートのお知らせ';

  @override
  String get updateButton => '今すぐアップデート';

  @override
  String get updateMessageDefault => 'アップデートが必要です。';
}

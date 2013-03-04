#source: http://en.wikipedia.org/wiki/List_of_Taiwanese_people

logger = require "./logconfig"
twPeople = []

# actors and actresses
actors =[
  {english: "Annie Shizuka Inoh", name: "伊能静"},
    {english: "Chen Bo-lin", name: "陳伯霖"},
    {english: "Chang Chen", name: "張震"},
    {english: "Brandon Chang", name: "張卓楠"},
    {english: "Brigitte Lin", name: "林青霞"},
    {english: "Huang He", name: "黃河"},
    {english: "Jerry Yan", name: "言承旭"},
    {english: "Joe Chen Qiao En", name: "陳喬恩"},
    {english: "Joey Wong", name: "王祖賢"},
    {english: "Ken Chu", name: "朱孝天"},
    {english: "Jimmy Lin", name: "林志穎"},
    {english: "Ruby Lin", name: "林心如"},
    {english: "Vanness Wu", name: "吳建豪"},
    {english: "Vic Chou", name: "周渝民"},
    {english: "Kelly Lin", name: "林熙蕾"},
    {english: "Barbie Hsu", name: "徐熙媛"},
    {english: "Ariel Lin", name: "林依晨"},
    {english: "Chang Shu-hao", name: "張書豪"},
    {english: "Takeshi Kaneshiro", name: "金城武"},
    {english: "Nicky Wu", name: "吳奇隆"},
    {english: "Show Luo", name: "羅志祥"},
    {english: "Jay Chou", name: "周杰倫"},
    {english: "Cindy Yen", name: "袁詠琳"},
    {english: "Chris Wang", name: "王宥勝"},
    {english: "Andrew Liu", name: "劉方荃"},
]

actors.map (el) ->
  el.field = "actor/actress"
  return el
twPeople = twPeople.concat actors

models =[
  {english: 'Lin Chi-ling', name: '林志玲'},
{english: 'Alicia Liu', name: '劉薰愛'},
{english: 'Faith Yang', name: '楊乃文'},
{english: 'Yinling', name: '垠凌'},
{english: 'Sonia Sui', name: '隋棠'}
]

models.map (el) ->
  el.field = 'model'
  return el
twPeople = twPeople.concat models


singers =[
  {english: 'Jimmy Lin', name: '林志穎'},
{english: 'Alec Su', name: '蘇有朋'},
{english: 'A-mei', name: '張惠妹'},
{english: 'Lollipop', name: '棒棒糖'},
{english: 'Brandon Chang', name: '張卓楠'},
{english: 'Jeff Chang', name: '張信哲'},
{english: 'Cheer Chen', name: '陳綺貞'},
{english: 'Chang Fei', name: '張菲'},
{english: 'Chen Ying-Git', name: '陳盈潔'},
{english: 'Chthonic', name: '閃靈'},
{english: 'Cindy Yen', name: '袁詠琳'},
{english: 'David Tao', name: '陶喆'},
{english: 'Elva Hsiao', name: '蕭亞軒'},
{english: 'Evan Yo', name: '蔡旻佑'},
{english: 'Evonne Hsu', name: '許慧欣'},
{english: 'F4', name: 'F4'},
{english: 'Fahrenheit',  name: 'Fahrenheit'},
{english: 'F.I.R', name: '飛兒樂團'},
{english: 'Fei Yu Ching', name: '費玉清'},
{english: 'Freya Lim', name: '林凡'},
{english: 'Peggy Hsu', name: '許哲珮'},
{english: 'i.n.g', name: 'i.n.g'},
{english: 'Jay Chou', name: '周杰倫'},
{english: 'Jerry Yan', name: '言承旭'},
{english: 'Jody Chiang', name: '江蕙'},
{english: 'Jolin Tsai', name: '蔡依林'},
{english: 'Kang Jing Rong', name: '康康'},
{english: 'Ken Chu', name: '朱孝天'},
{english: 'Landy Wen', name: '溫嵐'},
{english: 'Leehom Wang', name: '王力宏'},
{english: 'Machi[disambiguation needed]', name: '麻吉'},
{english: 'Takeshi Kaneshiro', name: '金城武'},
{english: 'Rainie Yang', name: '楊丞琳'},
{english: 'Richie Ren', name: '任賢齊'},
{english: 'Seraphim', name: 'Seraphim'},
{english: 'Show Luo', name: '羅志祥'},
{english: 'Sodagreen', name: '蘇打綠'},
{english: 'Seraphim', name: '六翼天使'},
{english: 'S.H.E', name: 'S.H.E'},
{english: 'Nicky Wu', name: '吳奇隆'},
{english: 'Tank', name: '吕建忠'},
{english: 'Teresa Teng', name: '鄧麗君'},
{english: 'Tim Wu', name: '金力若'},
{english: 'Tsai Chin', name: '蔡琴'}
{english: 'Typhoon', name: 'Typhoon'}
{english: 'Vivian Hsu', name: '徐若瑄'},
{english: 'Wilber Pan', name: '潘瑋柏'},
{english: 'Wu Bai', name: '伍佰'},
{english: 'Mayday', name: '五月天'},
{english: 'Jacky Wu', name: '吳宗憲'},
{english: 'Chou Chuan-huing', name: '周傳雄'},
{english: 'Vic Zhou', name: '周渝民'}
]

singers.map (el) ->
  el.field = 'singer'
  return el
twPeople = twPeople.concat singers


musicians = [
    {english: 'Chen Cheng-po', name: '陳澄波'},
    {english: 'Lee Tze-Fan', name: '李澤藩'},
    {english: 'Liu Chi-hsiang', name: '劉啟祥'},
    {english: 'Yen Shui-long, sculptor', name: '顏水龍'},
    {english: 'Lee Shih-chiao', name: '李石樵'},
    {english: 'Suling Wang', name: '王淑鈴'},
    {english: 'Jimmy Liao', name: '幾米'},
    {english: 'Yang Maolin', name: '楊茂林'},
    {english: 'Chen Uen', name: '鄭問'},
    {english: 'Lín Qīnghuì', name: '林青慧'}
]
musicians.map (el) ->
  el.field = 'musician'
  return el
twPeople = twPeople.concat musicians

artists = [
  {english: 'Chen Cheng-po', name: '陳澄波'},
    {english: 'Lee Tze-Fan', name: '李澤藩'},
    {english: 'Liu Chi-hsiang', name: '劉啟祥'},
    {english: 'Yen Shui-long, sculptor', name: '顏水龍'},
    {english: 'Lee Shih-chiao', name: '李石樵'},
    {english: 'Suling Wang', name: '王淑鈴'},
    {english: 'Jimmy Liao', name: '幾米'},
    {english: 'Yang Maolin', name: '楊茂林'},
    {english: 'Chen Uen', name: '鄭問'},
    {english: 'Lin Qinghui', name: '林青慧'}
]

artists.map (el) ->
  el.field = 'artist'
  return

twPeople = twPeople.concat artists

filmMakers =[
    {english: 'Ang Lee', name: '李安'},
    {english: 'Hou Hsiao-Hsien', name: '侯孝賢'},
    {english: 'Wei Te-Sheng', name: '魏德聖'}
]

filmMakers.map (el) ->
  el.field = 'film maker'
  return el
twPeople = twPeople.concat filmMakers

politicians =[
    {english: 'Tsai Ing-wen', name: '蔡英文'},
    {english: 'John Chiang', name: '蔣孝嚴'},
    {english: 'Chen Li-an', name: '陳履安'},
    {english: 'Chen Shui-bian', name: '陳水扁'},
    {english: 'Sisy Chen', name: '陳文茜'},
    {english: 'Chang Chau-hsiung', name: '張昭雄'},
    {english: 'Chiang Ching-kuo', name: '蔣經國'},
    {english: 'Chiang Wei-kuo', name: '蔣緯國'},
    {english: 'Frank Hsieh', name: '謝長廷'},
    {english: 'Lee Teng-hui', name: '李登輝'},
    {english: 'Lien Chan', name: '連戰'},
    {english: 'Lin Yang-kang', name: '林洋港'},
    {english: 'Annette Lu', name: '呂秀蓮'},
    {english: 'Ma Ying-jeou', name: '馬英九'},
    {english: 'Vincent Siew', name: '蕭萬長'},
    {english: 'James Soong', name: '宋楚瑜'},
    {english: 'Su Tseng-chang', name: '蘇真昌'},
    {english: 'Sun Yun-suan', name: '孫運璿'},
    {english: 'Yu Shyi-kun', name: '游錫堃'},
    {english: 'Wang Chien-shien', name: '王建煊'},
    {english: 'Wang Jin-pyng', name: '王金平'}
]

politicians.map (el) ->
  el.field = 'politician'
  return el
twPeople = twPeople.concat politicians

module.exports = exports = twPeople


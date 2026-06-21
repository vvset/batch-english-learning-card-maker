# Graded English Card Library

Use this reference when a user asks for cards by age range, school stage, or learning level.

For vocabulary-heavy requests, load [graded-word-bank-100.md](graded-word-bank-100.md). It contains 100 word records for each preset below.

## Source Anchors

- Cambridge Young Learners levels are useful anchors: Pre A1 Starters, A1 Movers, and A2 Flyers.
- British Council describes Young Learners preparation as suitable for children aged about 7 to 12.
- CEFR A1/A2 descriptors are useful for keeping sentences simple and practical.
- Do not copy a full external wordlist into output. Use this local seed bank first, then create original age-appropriate records in the same style.

## Stage Map

| User request | Preset | Difficulty | Content style |
| --- | --- | --- | --- |
| 3-5岁, 幼儿启蒙 | preschool-3-5 | Oral exposure | Single words, greetings, feelings, colors, toys, animals |
| 5-6岁, 幼儿园, 学前班 | kindergarten-5-6 | Pre-A1 starter | Short daily sentences, family, food, classroom, actions |
| 6-7岁, 一年级 | grade-1-6-7 | Pre-A1 to early A1 | Simple subject + verb sentences, school routines, likes |
| 7-8岁, 二年级 | grade-2-7-8 | A1 foundation | Can, have, there is/are, simple descriptions |
| 8-9岁, 三年级 | grade-3-8-9 | A1 | Daily life, weather, time, places, simple questions |
| 9-12岁, 小学中高年级 | primary-4-6-9-12 | A1 to early A2 | Longer but still clear sentences, hobbies, plans, comparisons |

## Selection Rules

- If the user gives only an age range, use the closest preset and include both sentence and word cards.
- If the user gives only a stage, use the mapped preset.
- If the user gives a count, fill that exact count.
- For word cards, select from `graded-word-bank-100.md` first.
- If the requested word count exceeds 100 for one preset, generate additional records with the same theme and difficulty.
- If the requested sentence count exceeds the sentence seed bank, generate additional records with the same grammar, theme, and length.
- Keep sentence cards to one natural sentence unless the user requests dialogues.
- For words, include one child-friendly example sentence when space allows.

## Seed Bank CSV

Columns:

```csv
preset,type,english,phonetic,meaning,example,example_meaning
```

```csv
preschool-3-5,word,red,/red/,红色,The ball is red.,这个球是红色的。
preschool-3-5,word,blue,/bluː/,蓝色,The sky is blue.,天空是蓝色的。
preschool-3-5,word,cat,/kæt/,猫,I see a cat.,我看见一只猫。
preschool-3-5,word,dog,/dɔːɡ/,狗,The dog is happy.,这只狗很开心。
preschool-3-5,word,sun,/sʌn/,太阳,The sun is warm.,太阳很温暖。
preschool-3-5,word,moon,/muːn/,月亮,The moon is bright.,月亮很明亮。
preschool-3-5,word,ball,/bɔːl/,球,I have a ball.,我有一个球。
preschool-3-5,word,toy,/tɔɪ/,玩具,This is my toy.,这是我的玩具。
preschool-3-5,word,milk,/mɪlk/,牛奶,I drink milk.,我喝牛奶。
preschool-3-5,word,happy,/ˈhæpi/,开心的,I am happy.,我很开心。
preschool-3-5,sentence,Hi.,/haɪ/,你好。,, 
preschool-3-5,sentence,Bye.,/baɪ/,再见。,, 
preschool-3-5,sentence,Thank you.,/ˈθæŋk juː/,谢谢你。,, 
preschool-3-5,sentence,I am happy.,/aɪ æm ˈhæpi/,我很开心。,, 
preschool-3-5,sentence,I see a cat.,/aɪ siː ə kæt/,我看见一只猫。,, 
preschool-3-5,sentence,Let's play.,/lets pleɪ/,我们玩吧。,, 

kindergarten-5-6,word,apple,/ˈæpəl/,苹果,I eat an apple.,我吃一个苹果。
kindergarten-5-6,word,book,/bʊk/,书,This is my book.,这是我的书。
kindergarten-5-6,word,chair,/tʃer/,椅子,Sit on the chair.,坐在椅子上。
kindergarten-5-6,word,door,/dɔːr/,门,Open the door.,打开门。
kindergarten-5-6,word,flower,/ˈflaʊər/,花,The flower is pretty.,这朵花很漂亮。
kindergarten-5-6,word,friend,/frend/,朋友,You are my friend.,你是我的朋友。
kindergarten-5-6,word,water,/ˈwɔːtər/,水,I drink water.,我喝水。
kindergarten-5-6,word,school,/skuːl/,学校,I go to school.,我去上学。
kindergarten-5-6,word,teacher,/ˈtiːtʃər/,老师,My teacher is kind.,我的老师很亲切。
kindergarten-5-6,word,small,/smɔːl/,小的,It is a small bag.,这是一个小包。
kindergarten-5-6,sentence,Good morning.,/ɡʊd ˈmɔːrnɪŋ/,早上好。,, 
kindergarten-5-6,sentence,My name is Lily.,/maɪ neɪm ɪz ˈlɪli/,我的名字叫莉莉。,, 
kindergarten-5-6,sentence,I like apples.,/aɪ laɪk ˈæpəlz/,我喜欢苹果。,, 
kindergarten-5-6,sentence,This is my bag.,/ðɪs ɪz maɪ bæɡ/,这是我的包。,, 
kindergarten-5-6,sentence,Please sit down.,/pliːz sɪt daʊn/,请坐下。,, 
kindergarten-5-6,sentence,Open your book.,/ˈoʊpən jʊr bʊk/,打开你的书。,, 
kindergarten-5-6,sentence,Have a nice day.,/hæv ə naɪs deɪ/,祝你今天愉快。,, 

grade-1-6-7,word,family,/ˈfæməli/,家庭,This is my family.,这是我的家庭。
grade-1-6-7,word,mother,/ˈmʌðər/,妈妈,My mother is kind.,我的妈妈很亲切。
grade-1-6-7,word,father,/ˈfɑːðər/,爸爸,My father is tall.,我的爸爸很高。
grade-1-6-7,word,pencil,/ˈpensəl/,铅笔,I have a pencil.,我有一支铅笔。
grade-1-6-7,word,ruler,/ˈruːlər/,尺子,This ruler is long.,这把尺子很长。
grade-1-6-7,word,read,/riːd/,阅读,I like to read.,我喜欢阅读。
grade-1-6-7,word,write,/raɪt/,写,I can write my name.,我会写我的名字。
grade-1-6-7,word,draw,/drɔː/,画画,I draw a tree.,我画一棵树。
grade-1-6-7,word,play,/pleɪ/,玩,We play after class.,我们课后玩。
grade-1-6-7,word,kind,/kaɪnd/,友善的,My friend is kind.,我的朋友很友善。
grade-1-6-7,sentence,I like reading.,/aɪ laɪk ˈriːdɪŋ/,我喜欢阅读。,, 
grade-1-6-7,sentence,This is my pencil.,/ðɪs ɪz maɪ ˈpensəl/,这是我的铅笔。,, 
grade-1-6-7,sentence,I can draw a star.,/aɪ kæn drɔː ə stɑːr/,我会画一颗星星。,, 
grade-1-6-7,sentence,We are friends.,/wiː ɑːr frendz/,我们是朋友。,, 
grade-1-6-7,sentence,The sun is shining.,/ðə sʌn ɪz ˈʃaɪnɪŋ/,阳光明媚。,, 
grade-1-6-7,sentence,Let's read together.,/lets riːd təˈɡeðər/,我们一起读吧。,, 

grade-2-7-8,word,breakfast,/ˈbrekfəst/,早餐,I eat breakfast at seven.,我七点吃早餐。
grade-2-7-8,word,lunch,/lʌntʃ/,午餐,We have lunch at school.,我们在学校吃午餐。
grade-2-7-8,word,dinner,/ˈdɪnər/,晚餐,Dinner is ready.,晚餐准备好了。
grade-2-7-8,word,weather,/ˈweðər/,天气,The weather is nice.,天气很好。
grade-2-7-8,word,rainy,/ˈreɪni/,下雨的,It is rainy today.,今天下雨。
grade-2-7-8,word,sunny,/ˈsʌni/,晴朗的,It is sunny today.,今天晴朗。
grade-2-7-8,word,library,/ˈlaɪbreri/,图书馆,I read in the library.,我在图书馆读书。
grade-2-7-8,word,homework,/ˈhoʊmwɜːrk/,家庭作业,I do my homework.,我做家庭作业。
grade-2-7-8,sentence,I can ride a bike.,/aɪ kæn raɪd ə baɪk/,我会骑自行车。,, 
grade-2-7-8,sentence,There is a book on the desk.,/ðer ɪz ə bʊk ɑːn ðə desk/,桌子上有一本书。,, 
grade-2-7-8,sentence,I have two pencils.,/aɪ hæv tuː ˈpensəlz/,我有两支铅笔。,, 
grade-2-7-8,sentence,It is rainy today.,/ɪt ɪz ˈreɪni təˈdeɪ/,今天下雨。,, 
grade-2-7-8,sentence,She is my teacher.,/ʃiː ɪz maɪ ˈtiːtʃər/,她是我的老师。,, 
grade-2-7-8,sentence,Can you help me?,/kæn juː help miː/,你能帮我吗？,, 

grade-3-8-9,word,hobby,/ˈhɑːbi/,爱好,My hobby is painting.,我的爱好是画画。
grade-3-8-9,word,music,/ˈmjuːzɪk/,音乐,I like music.,我喜欢音乐。
grade-3-8-9,word,sport,/spɔːrt/,运动,Football is a sport.,足球是一项运动。
grade-3-8-9,word,market,/ˈmɑːrkɪt/,市场,We go to the market.,我们去市场。
grade-3-8-9,word,animal,/ˈænɪməl/,动物,A rabbit is an animal.,兔子是一种动物。
grade-3-8-9,word,healthy,/ˈhelθi/,健康的,Fruit is healthy.,水果是健康的。
grade-3-8-9,word,quiet,/ˈkwaɪət/,安静的,The library is quiet.,图书馆很安静。
grade-3-8-9,word,question,/ˈkwestʃən/,问题,I have a question.,我有一个问题。
grade-3-8-9,sentence,What time is it?,/wʌt taɪm ɪz ɪt/,现在几点了？,, 
grade-3-8-9,sentence,My hobby is drawing.,/maɪ ˈhɑːbi ɪz ˈdrɔːɪŋ/,我的爱好是画画。,, 
grade-3-8-9,sentence,We go to the park on Sunday.,/wiː ɡoʊ tuː ðə pɑːrk ɑːn ˈsʌndeɪ/,我们星期天去公园。,, 
grade-3-8-9,sentence,I want a glass of water.,/aɪ wɑːnt ə ɡlæs əv ˈwɔːtər/,我想要一杯水。,, 
grade-3-8-9,sentence,The classroom is clean and bright.,/ðə ˈklæsruːm ɪz kliːn ænd braɪt/,教室干净又明亮。,, 

primary-4-6-9-12,word,practice,/ˈpræktɪs/,练习,Practice makes us better.,练习让我们变得更好。
primary-4-6-9-12,word,science,/ˈsaɪəns/,科学,Science is interesting.,科学很有趣。
primary-4-6-9-12,word,history,/ˈhɪstəri/,历史,We learn history at school.,我们在学校学习历史。
primary-4-6-9-12,word,journey,/ˈdʒɜːrni/,旅行,The journey is exciting.,这次旅行令人兴奋。
primary-4-6-9-12,word,careful,/ˈkerfəl/,小心的,Be careful on the road.,在路上要小心。
primary-4-6-9-12,word,important,/ɪmˈpɔːrtənt/,重要的,Water is important.,水很重要。
primary-4-6-9-12,word,beautiful,/ˈbjuːtɪfəl/,美丽的,The garden is beautiful.,花园很美丽。
primary-4-6-9-12,word,tomorrow,/təˈmɑːroʊ/,明天,See you tomorrow.,明天见。
primary-4-6-9-12,sentence,I am going to visit my grandparents.,/aɪ æm ˈɡoʊɪŋ tuː ˈvɪzɪt maɪ ˈɡrændperənts/,我打算去看望我的祖父母。,, 
primary-4-6-9-12,sentence,Reading every day is a good habit.,/ˈriːdɪŋ ˈevri deɪ ɪz ə ɡʊd ˈhæbɪt/,每天阅读是一个好习惯。,, 
primary-4-6-9-12,sentence,We should keep our classroom clean.,/wiː ʃʊd kiːp aʊr ˈklæsruːm kliːn/,我们应该保持教室干净。,, 
primary-4-6-9-12,sentence,This story is more interesting than that one.,/ðɪs ˈstɔːri ɪz mɔːr ˈɪntrəstɪŋ ðæn ðæt wʌn/,这个故事比那个更有趣。,, 
primary-4-6-9-12,sentence,I want to learn English with my friends.,/aɪ wɑːnt tuː lɜːrn ˈɪŋɡlɪʃ wɪð maɪ frendz/,我想和朋友们一起学英语。,, 
```

## Expansion Templates

Use these templates to create more original records when the user requests a larger batch.

### Preschool / Kindergarten

- `I see a {noun}.` / 我看见一个/一只{noun_cn}。
- `It is {color}.` / 它是{color_cn}的。
- `I like {food_plural}.` / 我喜欢{food_cn}。
- `This is my {object}.` / 这是我的{object_cn}。

### Grade 1-2

- `I can {verb}.` / 我会{verb_cn}。
- `I have {number} {noun_plural}.` / 我有{number_cn}个{noun_cn}。
- `There is a {noun} on the {place}.` / {place_cn}上有一个{noun_cn}。
- `{person} is my {role}.` / {person_cn}是我的{role_cn}。

### Grade 3-6

- `My hobby is {gerund}.` / 我的爱好是{gerund_cn}。
- `We go to the {place} on {day}.` / 我们{day_cn}去{place_cn}。
- `{noun} is important for us.` / {noun_cn}对我们很重要。
- `I want to {verb_phrase} with my friends.` / 我想和朋友们一起{verb_phrase_cn}。

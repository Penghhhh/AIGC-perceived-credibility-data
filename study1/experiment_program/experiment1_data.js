const express = require('express');
const path = require('path');  
const app = express();  
const port = 5500;  
  
// 设置EJS为模板引擎，并指定模板目录  
app.set('views', path.join(__dirname, 'views'));  
app.set('view engine', 'ejs');  
  
// 设置静态文件目录  
app.use(express.static(path.join(__dirname, 'public'))); // 假设静态文件（如图片）放在public目录下  

  
// 创建一个包含6个'1'和6个'0'的数组  
const ones = Array(2).fill('1');  
const zeros = Array(2).fill('0');  
  
// 将两个数组合并成一个包含10个元素的数组  
const combinedArray = [...ones, ...zeros];  
  
// 使用shuffle函数打乱数组顺序  
function shuffle(array) {  
  for (let i = array.length - 1; i > 0; i--) {  
    const j = Math.floor(Math.random() * (i + 1));  
    [array[i], array[j]] = [array[j], array[i]]; // 使用解构赋值来交换元素  
  }  
  return array;  
}  

// 打乱数组顺序  
const shuffledArray1 = shuffle(combinedArray);  
const shuffledArray2 = shuffle(combinedArray);  
const shuffledArray3 = shuffle(combinedArray);  
const shuffledArray4 = shuffle(combinedArray);  
const shuffledArray5 = shuffle(combinedArray);    

// 路由示例，模拟商品数据  
const products = [  
    {  
        id: 1,  
        name: 'xiaomi watch s3小米智能eSIM手表手环血氧健康睡眠独立打电话/s4',  
        sales: '5万',
        price: '1199',
        deliveryfrom: '湖北 武汉',
        imageUrls: [
            'https://gw.alicdn.com/imgextra/O1CN019Ezlix1thMqtOOIW0_!!2201407795933-0-yinheaigc.jpg_q50.jpg_.webp',
            'https://gw.alicdn.com/imgextra/O1CN01ZZRkWd1thMmq7i7aE_!!2201407795933.jpg_q50.jpg_.webp',
            'https://gw.alicdn.com/imgextra/O1CN01eBKGQL1thMmn2RojO_!!2201407795933.jpg_q50.jpg_.webp',
            'https://gw.alicdn.com/imgextra/O1CN010dU0HB1thMmn2QbwK_!!2201407795933.jpg_q50.jpg_.webp',
            'https://gw.alicdn.com/imgextra/O1CN01cS1osK1thMmsb7P8E_!!2201407795933.jpg_q50.jpg_.webp',
            '../goods/goods1_parameters.png'
        ],  
        descriptions: [  
            {
                cnum: 1, username: '用户58571914 ', commentDate: '3天前', isAI: shuffledArray1[0], pilot_num: 5,
                text:'颜值还不错，功能也还不错，但是发现一个很严重的问题，昨天收货的，今天中午开始激活使用，两个小时的时间，表环掉了两次了，掉的时候幸好都被我看到了，下次万一没注意到掉了怎么办？这是不是设计有问题？买个表生怕环掉了，还不省心。'
            },  
            {
                cnum: 2, username: '用户30755674', commentDate: '3天前', isAI: shuffledArray1[1], pilot_num: 7,
                text:'后壳上有个金属圈的是粘上去的，天气热它会掉下来，感觉是属于质量问题及设计缺陷，同时手表出现无法开机的情况。售后的过程中，小圆圈和手表一起交给快递。然后不知道在哪里，那个小圆圈掉了。然后京东走小米售后，小米售后电话里，很生硬的回复我要换后壳，维修费好像是200不到的样子，让人觉得很气愤。'
            },
            {
                cnum: 3, username: '用户671080796', commentDate: '3天前', isAI: shuffledArray1[2], pilot_num: 10,
                text:'这款产品我已经种草很久了，终于在此次促销活动时入手了。\n'+
                '续航能力：充满电后，整个工作时间蓝牙一直连接，处理微信通知、接打电话等，电量只消耗了6%，表现很出色。\n'+
                '触控效果：操作非常顺滑，体验感很好。\n'+
                '外观材质：做工和质量都很不错，只是对于女生来说，戴起来稍微显得有些大。'
            }, 
            {
                cnum: 4, username: '用户231279929', commentDate: '3天前', isAI: shuffledArray1[3], pilot_num: 12,
                text:'小米智能手表S3是一款集健康监测、运动追踪和智能提醒于一体的智能设备。它采用高品质不锈钢表壳和硅胶表带，屏幕清晰明亮，支持全天候心率监测、血氧检测和睡眠追踪，并内置多种运动模式。用户反馈其操作简便，佩戴舒适，性能稳定。凭借出色的性价比，这款手表成为了推荐的理想选择。'
            }
        ]  
    },  
    {
        id: 2,  
        name: '华凌双排神机空调35HE1Pro大1.5匹一级智能家用挂机壁挂式卧室',  
        sales: '7万',
        price: '2199',
        deliveryfrom: '德州仓',
        imageUrls: [
            'https://img.alicdn.com/imgextra/i2/2206358644076/O1CN01nuH28h1fyrM7qHQoS_!!0-item_pic.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i3/2206358644076/O1CN0128G79s1fyrLp8Pc2z_!!2206358644076.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i2/2206358644076/O1CN01CiXkdj1fyrLrnmfze_!!2206358644076.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i4/2206358644076/O1CN01QKRUiB1fyrLRtAMpQ_!!2206358644076.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i1/2206358644076/O1CN018eALMI1fyrKjp7Pf6_!!2206358644076.jpg_q50.jpg_.webp',
            '../goods/goods2_parameters.png'
        ],  
        descriptions: [  
            {
                cnum: 1, username: '用户95451839', commentDate: '3天前', isAI: shuffledArray2[0], pilot_num: 4,
                text:
                '1.空调比我想的要好点，制冷非常好用。这款空调，内机外机都十分美观，做工精细，制冷效果好，运行声音小，带温度显示的宇体很大，十分人性化，售后6年保修，让消费者省心，第一次网购空调，很满意。\n' +
                '2.节能效果很好，平时就开 26度也很省电，空调风速很大，很静音，制冷很快。\n' +
                '3.空调颜值好看，空调做工精细，运行静音节能，新一级能耗超级省电。\n' +
                '4.安装的很快，声音很轻，冷暖还没测试，外观美观，听说很省电，送货也很快，安装服务很好。\n' +
                '5.发货送货速度快，下午送货下午安装，全部完工，试了声音很小，带有光感睡眠，整体美观，空调效果不错。\n' +
                '6.空调质量很好，外观设计很大气，适合多种家居风格，制冷效果很好，静音效果也很好，节能省电，真的很满意'
            },
            {
                cnum: 2, username: '用户71510289', commentDate: '3天前', isAI: shuffledArray2[1], pilot_num: 5,
                text:
                '华凌35HE1Pro大1.5匹空调，真乃家用神器！制冷制热迅速，开机即享清凉与温暖，房间迅速降温，风速可调，避免冷风直吹，舒适感倍增。其新一级能效标识，APF高达5.30，节能省电效果显著，ECO模式下更是低耗运行，电费无忧。\n' +
                '智能操控是一大亮点，通过手机APP远程调控，随心所欲，便捷至极。超宽导风板结合多维扫风，送风均匀广泛，睡眠模式更是贴心，根据人体需求自动调节，营造一夜好眠。\n' +
                '自清洁功能让人省心省力，保持空气清新，健康守护每一天。价格上更是亲民，性价比超高，市场难寻同价位如此配置之选。\n' +
                '当然，品牌知名度上虽不及传统大牌，但性价比足以弥补。'
            }, 
            {
                cnum: 3, username: '用户27661548', commentDate: '3天前', isAI: shuffledArray2[2], pilot_num: 6,
                text:
                '华凌35HE1Pro空调的使用体验让我非常失望。首先，制冷效果远低于预期，尤其在高温天气时，房间降温速度非常慢，让人感到煎熬。虽然风速有多档可调，但实际效果并不明显，冷风直吹的问题依然存在，舒适度大大降低。虽然能效标识显示较高，但在实际使用中并没有明显感受到省电效果，电费支出也没有像宣传中那样减少，这让人对其节能性能产生了质疑。\n' +
                '此外，智能功能看似先进，但APP操作经常卡顿，远程控制也不够稳定，影响了整体使用的便捷性。自清洁功能的效果也有限，仍需定期手动清洁，跟宣传中的“省心省力”相差甚远。虽然在价格上相较于某些品牌有一定优势，但考虑到实际使用体验与宣传不符，其性价比并不突出。' 
            },  
            {
                cnum: 4, username: '用户23814765', commentDate: '3天前', isAI: shuffledArray2[3], pilot_num: 8,
                text:
                '华凌35HE1Pro空调虽价格亲民，但使用体验却令人颇为失望。在小卧室中，其制冷速度尚可，但问题重重。首先，窗户适配性差，即便使用额外绝缘条与胶带，仍有明显缝隙，影响隔音且易进蚊虫。其次，温度调控极不稳定，无论是低档还是高档，室内温度波动大，需频繁调整，难以维持舒适区间。再者，运行时噪音问题突出，频繁启停伴随刺耳蜂鸣声，影响休息。\n' +
                '此外，该空调高功耗问题也需留意，与家中其他电器共用电源时，易引发跳闸。综合而言，华凌35HE1Pro虽能带来一时凉爽，但在温度控制、噪音处理及耐用性上均有待提升。若非预算有限或对温度波动不敏感者，建议慎重考虑，以免影响生活品质。'
            }
        ] 
     },  
    {
        id: 3, 
        name: '坚果投影Nano 2智能云台投影仪家用家庭客厅卧室小型便携式投影机微型影院学生宿舍手机游戏投屏', 
        sales: '8万',
        price: '1799',
        deliveryfrom: '广东东莞',
        imageUrls: [
            'https://img.alicdn.com/imgextra/i1/2587461980/O1CN01T9E1E41QUtCfzc4lt_!!0-item_pic.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i3/2587461980/O1CN01NWPCuZ1QUtCTUDazy_!!2587461980.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i4/2587461980/O1CN01GwDwz81QUtCRbWZIy_!!2587461980.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i2/2587461980/O1CN017MSMVK1QUtCTGlrEP_!!2587461980.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i4/2587461980/O1CN01V5TT5i1QUtCKkJxQJ_!!2587461980.jpg_q50.jpg_.webp',
            '../goods/goods3_parameters.png'
        ],
        descriptions: [  
            {
                cnum: 1, username: '用户29315764', commentDate: '3天前', isAI: shuffledArray3[0], pilot_num: 3,
                text:
                '在对比了新购的坚果投影仪与我原有的极米6X后，我发现两者在亮度上确有显著不同，新投影明显更亮，为观影带来了更为明亮的视觉效果。然而，近距离观察时，新投影的画面却出现了不少噪点，如同细微的小雪花，整体色调也显得过于鲜艳，缺乏极米6X那种温润柔和的质感。这种差异在单独使用时或许不太明显，但一经对比便显得尤为突出。\n\n'+
                '至于外观，坚果投影仪比预想中要小巧许多，奶白色的机身搭配小巧的电源，整体显得十分可爱，便于携带与摆放。特别是它的支架设计，让我可以轻松将其置于床头，无需额外垫高。\n\n' +
                '但在实际使用中，投影画面的质感却让我感到有些不适。画面似乎被一层薄雾笼罩，带有毛玻璃般的朦胧感，长时间观看不仅让我感到眼睛疲劳，甚至出现了重影现象，家人也有同感。考虑到对视力可能产生的潜在影响，尤其是担心影响家中小朋友的视力健康，我最终决定退掉这款投影仪。此外，尽管其音质表现尚可，声音大小适中，但略显沉闷，可能与投影体积较小、音腔受限有关。'
            },
            {
                cnum: 2, username: '用户56410927', commentDate: '3天前', isAI: shuffledArray3[1], pilot_num: 4,
                text:
                '坚果投影仪以其小巧精致的外观，完美契合我的家庭使用环境。其投影亮度智能可调，无论是开灯还是关灯环境，都能确保画面清晰明亮，满足不同场景下的观影需求。实际投影色彩虽在手机拍摄下略显发红，但亲眼所见却是异常清晰真实，色彩饱满。音质方面，坚果投影仪在客厅环境下表现出色，音效浑厚有力，足以满足我们家庭日常娱乐需求。\n\n' +
                '操作方面，简便快捷，功能布局直观易懂，搭配详尽的操作指引，即便是初次使用者也能迅速上手。与此同时，它支持多种智能设备无缝连接，无论是手机投屏还是远程操控，都能轻松实现，自由随心。此外，坚果投影仪的外观设计简约时尚，能够很好地融入各种家居风格中，既实用又美观。'
            },
            {
                cnum: 3, username: '用户32716385', commentDate: '3天前', isAI: shuffledArray3[2], pilot_num: 7,
                text:
                '自从入手了坚果Nano 2投影仪，我的家庭娱乐体验得到了极大提升。这款投影仪以其极致的便携性和智能的自动对焦、梯形校正功能，轻松满足了我在家庭客厅及外出旅行的多样需求。无论是在客厅享受电影时光，还是户外露营的夜晚观影，Nano 2都能迅速适应各种环境，一键设置，完美成像，省去了繁琐的手动调整步骤，让独自布置变得轻松愉快。\n\n' +
                '画质方面，坚果Nano 2展现出了卓越的表现力，色彩丰富饱满，对比度出色，即便在白天或光线较强的环境下，也能呈现清晰细腻的画面，大大超出了我的预期。配合高清输入接口，无论是连接4K Apple TV还是1080p Roku，都能自动适配最佳分辨率，展现最佳视觉效果。\n\n' +
                '此外，其内置蓝牙功能让外接音响变得简单快捷，与我的音响系统无缝连接，带来震撼的音效体验。即便使用内置扬声器，声音依然清晰响亮，足以满足日常需求。'
            },
            {
                cnum: 4, username: '用户85819246', commentDate: '3天前', isAI: shuffledArray3[3], pilot_num: 8,
                text:
                '我购买坚果Nano 2投影仪时，被其标称的520流明亮度所吸引，期望能在户外投射出明亮的150英寸画面。然而，实际使用时却发现画面异常昏暗。通过专业测试，我发现其真实亮度仅为160流明，与标称值相去甚远，差距高达数倍，实属虚假宣传。\n\n' +
                '此外，该投影仪的梯形校正功能也存在严重问题。当以向上角度投射时，尽管能调整图像至方形，但随之而来的画面模糊无法通过焦距调节来弥补，这显然是光学设计上的缺陷。这种模糊程度严重到几乎让人忽视了其标称的720P分辨率，画面清晰度大打折扣。\n\n' +
                '鉴于上述严重的虚假宣传和糟糕的光学表现，我最终决定退货。这次尝试不仅未能满足我的需求，反而浪费了宝贵的时间。对于考虑购买坚果Nano 2投影仪的朋友们，我建议三思而后行。'
            }
        ]  
    },
    { 
        id: 4, 
        name: '九号电动F90新国标电动车成人代步9号长续航智能电瓶车', 
        sales: '2万',
        price: '3599',
        deliveryfrom: '江苏苏州',
        imageUrls: [
            'https://img.alicdn.com/imgextra/i1/2207026946442/O1CN01wBTLbZ1xSURZMmLSQ_!!0-item_pic.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i1/2207026946442/O1CN01SboFEw1xSULLgNibp_!!2207026946442.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i3/2207026946442/O1CN01yRjFy41xSULhRywYM_!!0-item_pic.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i4/2207026946442/O1CN011rH8RM1xSUMriyPm3_!!2207026946442.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i2/2207026946442/O1CN01hqf3IH1xSUETMtfGV_!!2207026946442.jpg_q50.jpg_.webp',
            '../goods/goods4_parameters.png'
        ],
        descriptions: [ 
            {
                cnum: 1, username: '用户71218349', commentDate: '3天前', isAI: shuffledArray4[0], pilot_num: 2,
                text:
                '1.颜值真高哈哈，喜欢折腾的建议买白色然后再上一套自己喜欢的贴纸。\n' +
                '2.智能化真好使，状态检测，手机蓝牙开锁真是太方便了，这个价位太有性价比了。\n' +
                '3.定速巡航这个功能吹爆，长途骑行解放右手，用了就爱了。\n' +
                '4.续航问题目前还没有把电池用尽过，今天骑行了实际距离十二公里，耗电16%，如果电量指示正确的话，我再刨掉20%的虚电，50公里也是妥妥的。'
            }, 
            {
                cnum: 2, username: '用户47913672', commentDate: '3天前', isAI: shuffledArray4[1], pilot_num: 9,
                text:
                '1.关于电池与续航：电池经常出现虚电的情况，里程显示不准确，切换到经济档时最多只能跑到45公里。如果切换到运动档，续航估计只有36到37公里。当续航低于25公里后，每行驶3公里，实际行驶的里程却显示为4公里。这种表现让我感到非常失望，尤其是在天气并不太冷的情况下。\n' +
                '2.关于动力问题：当电量在90%以上时，动力表现正常。但当电量低于60%时，动力就明显不足，即使切换到运动档也是如此。尤其是当电池续航仅剩7到8公里时，最高也只能跑到25公里左右。\n' +
                '3.关于车身结构：刹车把手稍一碰就歪了，这也反映了外观简约和结构简单的缺陷。此外，车把也有些松动。我问了商家，得到的回复只是“没事”。但是这怎么可能是没事的？'
            },
            {
                cnum: 3, username: '用户921145837', commentDate: '3天前', isAI: shuffledArray4[2], pilot_num: 11,
                text:
                '在双十一期间，我花4899元购买了这款车，但在武汉还要额外加300元，真是让人失望！买下来后只是一辆裸车，后来又加了坐垫、尾箱、尾箱架和宝宝椅，算下来总共超过了6000元，基本上算是满配了！这个价位可以买到两辆传统品牌的60V20A电动车了，不过要看每个人的想法吧。\n' +
                '这款车确实不错，续航能力比铅酸电池的60V20A强一些。在十几度的环境下，单人骑行解限速的话，应该可以达到五六十公里。如果是双人骑行，最多也就四十公里。更换一个锂电池要花两千多，真是让人心惊！充电时间需要七八个小时，和铅酸电池差不多。\n' +
                '初段加速确实有些绵软无力，不过骑行过程中相对安全，感觉有点像自然吸气的汽车。中后段缓慢升速，动力表现尚可，但扭矩稍显不足。原厂轮胎感觉有点滑，驾驶时不太放心。连接手机后使用确实方便，不用再带钥匙。避震系统有点硬，但没有一般电动车那种晃晃悠悠的感觉，利弊参半。\n' +
                '总的来说，如果不差钱，尝鲜可以考虑；否则，价格翻倍就显得有些不必要。如果只是买菜或者送小孩的话，还是选便宜一点的车型比较合适。48V25A的续航表现也就是中规中矩。'
            },
            {
                cnum: 4, username: '用户681293275', commentDate: '3天前', isAI: shuffledArray4[3], pilot_num: 12,
                text:
                '由于之前那款小牛电动车的电池实在不够给力，所以我换成了九号F90。这款车超出了我的预期，非常智能，可以无需钥匙直接解锁，启动过程也非常流畅。轻轻一拧油门，车子便能平稳起步，整个加速过程自然，没有任何突兀的感觉。在路上行驶时，车身稳定，即使经过减速带或坑洼路面也不会感到明显的震动。坐在车上感觉轻盈自如，仿佛与车融为一体。轮胎厚实，整车没有异响，让人倍感安全。'
            }
        ] 
    },
    { 
        id: 5, 
        name: 'Sony/索尼 WH-1000XM5 高解析度无线降噪头戴耳机', 
        sales: '2万',
        price: '2999',
        deliveryfrom: '上海',
        imageUrls: [
            'https://img.alicdn.com/imgextra/i2/782731205/O1CN01HaMtTA1KlwFe2q5x3_!!0-item_pic.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i3/782731205/O1CN01EzmExv1KlwF8IXJ37_!!782731205.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i4/782731205/O1CN01EEPdeA1Klw5or88RS_!!782731205.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i1/782731205/O1CN01JzoHer1Klw7v3paUW_!!782731205.jpg_q50.jpg_.webp',
            'https://img.alicdn.com/imgextra/i3/782731205/O1CN01fquGTQ1Klw1JQIpi2_!!782731205.jpg_q50.jpg_.webp',
            '../goods/goods5_parameters.png'
        ],
        descriptions: [  
            {
                cnum: 1, username: '用户32716385', commentDate: '3天前', isAI: shuffledArray5[0], pilot_num: 7,
                text:
                '1.电池续航出色。\n' +
                '2.通话质量不错，但和Blueparrott B450-XT相比就差远了——Blue 450专为嘈杂环境下的通话设计。在我看来，Blue 450是评判所有主动降噪（ANC）通话耳机的标准。索尼的ANC算不上Blue 450那样顶级，人们说我听起来像是站在麦克风旁边的房间里，声音有点模糊，像是隔着鱼缸传出来的。所以，索尼耳机虽然能用于通话，但不适合在嘈杂环境中作为主要通话设备，但降噪效果优于bose 700，这也促使我选择了索尼。\n' +
                '3.索尼耳机还有一个非传统但很实用的功能：助眠。是的，它们能消除所有多余的声音，比如人们交谈的声音、空调声、风扇声、饮水机声、嗡嗡声等。即使不播放任何声音，这些噪音也会消失得无影无踪！我买它们主要是为了在PS5上玩游戏和晚上看电视。这两个方面它们都表现得很好。\n' +
                '4.即使长时间佩戴，我的耳朵也不会出太多汗。我还为它们买了Dekoni绒面革耳垫，以增加舒适度。长期佩戴也很舒适，不会挤耳朵。\n' +
                '6.至于音乐，我发现索尼耳机的声音比较平，没有突出的高音或低音——这正是我所喜欢的。应用程序中的均衡器（EQ）是一个不错的功能。在听音乐时，主动降噪功能非常出色，在安静和嘈杂的环境中都能很好地发挥作用。\n' +
                '7.价格方面，索尼耳机确实有点贵，但它们的做工质量似乎比大多数耳机都要好。我觉得还算物有所值。'
            },
            {
                cnum: 2, username: '用户85819246', commentDate: '3天前', isAI: shuffledArray5[1], pilot_num: 8,
                text:
                '这又是索尼的一款优秀产品，但价格过高。它的音质很棒，降噪效果也很好，电池续航也很惊人。不过，它也有一些缺点：\n' +
                '1.价格极其昂贵（性能并不能证明这个价格合理）。\n' +
                '2.降噪功能：如果你把耳机摘下来几秒钟，降噪功能就会消失……这个设置太烦人了。\n' +
                '3.音量控制：索尼把所有音量控制都取消了！和索尼之前耳机上的其他开关一样……所以现在你只有一个开机键，仅此而已！音量控制是通过上下滑动手指来实现的，比如你想暂停，需要双击。你需要点击正确的位置，否则它不会有用（你可能会在走路时点击耳机，而很难准确地点击到同一个位置！）音量增减也是如此。出于某种设计原因，音量调节是分阶段的，所以如果你想完全降低音量是做不到的，只能一点一点地降低，重复几次操作才能达到合适的音量。这太麻烦了，会浪费大量时间。\n' +
                '总的来说，耳机设计更偏向于工程师视角，而非用户体验，忽略了用户在实际使用中的便捷性需求。因此索尼耳机是一件很好的工程作品，但使用它 面临着巨大的挑战。我的建议是购买替代品，而不是花这么多钱购买一款旨在重新发明耳机的产品。'
            },
            {
                cnum: 3, username: '用户47913672', commentDate: '3天前', isAI: shuffledArray5[2], pilot_num: 9,
                text:
                '首先，让我谈谈这款索尼耳机的舒适度。它采用了轻盈的材质和人体工学设计，佩戴起来非常舒适，几乎没有压迫感。同时，它还配备了可调节的头梁和耳罩，可以根据用户的头型进行微调，确保佩戴稳定且贴合。\n' +
                '此外，这款耳机的隔音效果也非常出色，能够有效隔绝外界噪音，让用户在嘈杂的环境中也能专注于享受音乐。\n音质体验：在音质方面，这款索尼耳机同样表现优异。它采用了高分辨率音频技术，能够呈现出更为细腻、真实的音质。\n' +
                '无论是低频的震撼力、中频的饱满度还是高频的清晰度，都表现得非常出色。同时，它还支持多种音频编码格式，让用户能够根据自己的喜好和需求选择合适的音质设置。在聆听音乐时，我仿佛置身于一个专为我打造的音乐殿堂中，感受到了前所未有的音乐体验。'
            },
            {
                cnum: 4, username: '用户681293275', commentDate: '3天前', isAI: shuffledArray5[3], pilot_num: 12,
                text:
                '我一直是Sony耳机的粉丝，所以当WH-1000XM5发布时，我毫不犹豫地入手了。但说实话，这次的体验真的让我有点失望。' +
                '首先，降噪效果并没有我期待中的那么出色。在嘈杂的地铁里，我还是能听到不少外界的声音，感觉降噪效果并没有比前代提升多少。' +
                '然后，舒适度也有点问题。戴久了耳朵会感觉闷热，不如前代那么透气。特别是在夏天，这个问题更加明显。' +
                '音质方面，我觉得也没有太大的提升。虽然听起来还算清晰，但总觉得少了点Sony特有的那种韵味。' +
                '最让我头疼的是连接稳定性。有时候手机放在口袋里，耳机就会突然断连，特别是在我走得快或者跑步的时候。这对于喜欢边运动边听音乐的我来说，真的很不方便。' +
                '至于电池续航，虽然官方说能撑很久，但我感觉实际用起来并没有那么长。可能是因为我每天用得比较多吧，但总觉得需要更频繁地充电。'
            }, 
        ] 
    }
];  

//descriptions 随机排序
products.forEach(product => {  
    product.descriptions = shuffle(product.descriptions);  
});  
  

// 商品信息页面路由  
app.get('/goodsinfo.html', (req, res) => {  
    const productId = req.query.id; // 从查询字符串中获取商品ID  
    const product = products.find(p => p.id === parseInt(productId, 10)); // 查找对应的商品  
  
    if (product) {  
        res.render('goodsinfo', { product }); // 渲染商品信息页面并传递商品数据  
    } else {  
        res.status(404).send('商品未找到');  
    }  
});  
  
// 启动服务器  
app.listen(port, () => {  
    console.log(`Server running on port ${port}`);  
});
// 定义每个帖子的指导语
const descriptions = {
    1: "蜜雪冰城“隔夜柠檬”争议暴露了行业标准滞后与消费者认知升级的矛盾。广东卫健委将“隔夜”定义为切开后存放8-10小时，但公众普遍按字面理解，这种分歧源于茶饮行业缺乏统一的鲜切水果操作规范。消费者对冷藏超4小时的柠檬片产生安全疑虑，而部分人用家庭厨房标准类比，混淆了商业与家庭的安全要求。、\n\n" +  
        "蜜雪冰城的低价策略依赖规模化容忍微小瑕疵，但品控漏洞会因销量放大风险。建议企业引入AI监控、分级管理加盟商，明确鲜切水果“黄金4小时”使用期，超时转为他用。监管部门需制定《鲜切水果保存指南》，用数据明确储存标准，避免教条化。\n\n" +  
        "解决争议需多方共建信任：企业应可视化操作（如标注切割时间），消费者需区分家庭与商业安全标准，监管部门则聚焦高风险领域，加强科普。只有数据化标准与透明管理，才能将争议转化为行业升级的契机。",
    2: "橄榄油的健康价值存在争议。支持方引用西莫普勒斯博士研究，指出其ω-3与ω-6比例接近理想的1:4，类似母乳。卫生部2008年文件推荐用橄榄油替代其他食用油，地中海地区数据显示其使用者心血管疾病风险降低30%，得益于70%以上的单不饱和脂肪酸和抗氧化成分。\n\n" +  
        "质疑方指出橄榄油78%是人体可自合成的ω-9油酸，ω-3含量仅0.2%。地中海居民健康还依赖大量深海鱼类摄入，而中国饮食缺乏ω-3来源。更适合国人的是亚麻籽油等富含ω-3的油类，如牡丹籽油ω-3含量达42%，比例更优。\n\n" +  
        "若选用橄榄油，应选特级初榨（Extra Virgin），烟点190℃适合凉拌或低温烹饪。每日不超过25克，搭配柠檬汁促进吸收。避免透明瓶装精炼混合油，预算有限可用山茶油替代。需根据个人饮食结构科学选择。",
    3:  "华为Mate 70延续了系列经典的商务设计，云杉绿配色在不同光线下呈现独特质感，7.8mm轻薄机身携带方便，但直角边框影响握持舒适度。6.7英寸1.5K直屏显示细腻，120Hz刷新率流畅，户外2500nit亮度实用，不过低亮度均匀性有待改进。麒麟9010芯片日常使用流畅，但高负载游戏时会出现发热降频，实测《原神》半小时后温度达46度左右，性能释放偏保守。\n\n" +
        "影像系统表现中规中矩：5000万主摄直出色彩鲜艳，但长焦在暗光环境噪点明显，3.5倍变焦时画质下降显著，微距模式对焦成功率约77%。鸿蒙4.3系统在多设备协同上依然领先，但15%的主流应用（特别是金融类）存在适配问题。5300mAh电池续航扎实，支持全天中度使用，66W快充补电迅速，但边玩边充效率较低（30分钟仅充23%）。\n\n" +
        "Mate 70是台均衡的商务旗舰，适合注重品牌和系统体验的用户。如果你追求极致性能或专业摄影，建议考虑Pro版本或竞品旗舰。普通用户日常使用完全足够，但游戏玩家和摄影爱好者可能需要权衡取舍。",
    4: "隐性肥胖是内脏脂肪超标但外表不显胖的健康隐患。即使体重正常，肝脏、胰腺等内脏也可能被脂肪包围。常见诱因包括熬夜（扰乱代谢）、不吃早餐（触发节能模式）、久坐和晚食等不良习惯，遗传和某些疾病也会增加风险。\n\n" +  
        "危害远超想象，增加糖尿病、心血管疾病和多种癌症风险，可能导致不孕、关节问题和脂肪肝。英国研究显示内脏脂肪会损害肝脏、扰乱代谢，甚至提升心脏病发作概率。\n\n" + 
        "自测方法：1)腰臀比男性≥0.9/女性≥0.8；2)肚脐周围捏不起2cm；3)体脂率男性≥25%/女性≥30%。2012年数据显示39%体重正常人群存在隐性肥胖，男性比例更高达50%。\n\n" +  
        "应对建议：规律作息、均衡饮食（减少精制碳水/油炸食品）、增加活动量。特别要避免熬夜和饭后久坐，这些是内脏脂肪堆积的主因。"
};

const post_titles = {
    1: "蜜雪冰城24小时营业能否解决食品安全问题？",
    2: "橄榄油的价值和功效是否有科学依据？",
    3: "华为mate 70是否值得入手？",
    4: "什么是“隐形肥胖”？"
};

// 定义里克特量表选项
const likert_scale1 = [
    "非常不可信",
    "不可信",
    "比较不可信",
    "不太确定",
    "比较可信",
    "可信",
    "非常可信"
];
const likert_scale2 = [
    "一定是真人",
    "很可能是真人",
    "有可能是真人",
    "不太确定",
    "有可能是AI",
    "很可能是AI",
    "一定是AI"
];
const likert_scale3 = [
    "非常不认同",
    "不认同",
    "比较不认同",
    "不太确定",
    "比较认同",
    "认同",
    "非常认同"
];

// 定义标签类型
const label_type = [1, 2, 3, 4]; // 1: 显示label1和label2, 2: 只显示label1, 3: 只显示label2, 4: 两个标签均不显示
function shuffle(arr) {
    let i = arr.length;
    while (--i) {
        let j = Math.floor(Math.random() * i);
        [arr[j], arr[i]] = [arr[i], arr[j]];
    }
    return arr;
}
const shuffled_label_type = shuffle(label_type); // 随机打乱顺序

// 定义问卷内容
const questionnaires = {
    1: {
        scales: [
            { prompt: "您认为此篇帖子的可信度为：", name: 'P1Q1_L'+ shuffled_label_type[0], labels: likert_scale1, required: true },
            { prompt: "您认为此篇帖子的真实作者是：", name: 'P1Q2_L'+ shuffled_label_type[0], labels: likert_scale2, required: true },
            { prompt: `
                <div style="border: 1px dashed #ccc; padding: 10px; border-radius: 5px; margin-bottom: 15px;">
                    <div class="label-container-0" id="label_0" style="display: ${shuffled_label_type[0] === 4 ? 'flex' : 'none'}">
                        <div class="label" id="label_0_text">该帖子无标签</div>
                    </div>
                    <div class="label-container-1" id="label_1_q" style="display: ${shuffled_label_type[0] === 1 || shuffled_label_type[0] === 2 ? 'flex' : 'none'}">
                        <span class="iconfont icon-info"></span>
                        <div class="label">平台声明：内容疑似AI生成，请谨慎甄别</div>
                        <div class="why-label" style="line-height: normal; text-align: start">平台检测工具识别出该文字信息疑似经过人工智能技术（AIGC）合成。</div>
                    </div>
                    <div class="title-container">
                        <div class="title-text" style="text-align: start">蜜雪冰城24小时营业能否解决食品安全问题？</div>
                    </div>
                    <div class="info-container">
                        <div class="author-info">
                            <img src="avatar.png">
                            <div class="author-name" style="font-weight: 600;">用户</div>
                            <div class="date">编辑于2025-03-28</div>
                        </div>
                        <div class="label-container-2" id="label_2_q" style="display: ${shuffled_label_type[0] === 1 || shuffled_label_type[0] === 3 ? 'flex' : 'none'}">
                            <span class="iconfont icon-info"></span>
                            <div class="label">作者声明：内容使用AI创作</div>
                            <div class="why-label" style="line-height: normal; text-align: start">此提示语为"作者自主添加"，作者提示"该内容由人工智能生成技术（AIGC）创作"。</div>
                        </div>
                    </div>
                </div>
                <div style="margin-top: 20px;">请描述您对下述说法的认同程度<br>“阅读本文时，看到所显示的标签我感到不舒服”</div>
                `, 
                name: 'P1Q3_L'+ shuffled_label_type[0], labels: likert_scale3, required: true }
        ],
        label_type: shuffled_label_type[0] // 为帖子1分配随机的标签类型
    },
    2: {
        scales: [
            { prompt: "您认为此篇帖子的可信度为：", name: 'P2Q1_L'+ shuffled_label_type[1], labels: likert_scale1, required: true },
            { prompt: "您认为此篇帖子的真实作者是：", name: 'P2Q2_L'+ shuffled_label_type[1], labels: likert_scale2, required: true },
            { prompt: `
                <div style="border: 1px dashed #ccc; padding: 10px; border-radius: 5px; margin-bottom: 15px;">
                    <div class="label-container-0" id="label_0" style="display: ${shuffled_label_type[1] === 4 ? 'flex' : 'none'}">
                        <div class="label" id="label_0_text">该帖子无标签</div>
                    </div>
                    <div class="label-container-1" id="label_1_q" style="display: ${shuffled_label_type[1] === 1 || shuffled_label_type[1] === 2 ? 'flex' : 'none'}">
                        <span class="iconfont icon-info"></span>
                        <div class="label">平台声明：内容疑似AI生成，请谨慎甄别</div>
                        <div class="why-label" style="line-height: normal; text-align: start">平台检测工具识别出该文字信息疑似经过人工智能技术（AIGC）合成。</div>
                    </div>
                    <div class="title-container">
                        <div class="title-text">橄榄油的价值和功效是否有科学依据？</div>
                    </div>
                    <div class="info-container">
                        <div class="author-info">
                            <img src="avatar.png">
                            <div class="author-name" style="font-weight: 600;">用户</div>
                            <div class="date">编辑于2025-03-28</div>
                        </div>
                        <div class="label-container-2" id="label_2_q" style="display: ${shuffled_label_type[1] === 1 || shuffled_label_type[1] === 3 ? 'flex' : 'none'}">
                            <span class="iconfont icon-info"></span>
                            <div class="label">作者声明：内容使用AI创作</div>
                            <div class="why-label" style="line-height: normal; text-align: start">此提示语为"作者自主添加"，作者提示"该内容由人工智能生成技术（AIGC）创作"。</div>
                        </div>
                    </div>
                </div>
                <div style="margin-top: 20px;">请描述您对下述说法的认同程度<br>“阅读本文时，看到所显示的标签我感到不舒服”</div>
                `,  
                name: 'P2Q3_L'+ shuffled_label_type[1], labels: likert_scale3, required: true }
        ],
        label_type: shuffled_label_type[1] // 为帖子2分配随机的标签类型
    },
    3: {
        scales: [
            { prompt: "您认为此篇帖子的可信度为：", name: 'P3Q1_L'+ shuffled_label_type[2], labels: likert_scale1, required: true },
            { prompt: "您认为此篇帖子的真实作者是：", name: 'P3Q2_L'+ shuffled_label_type[2], labels: likert_scale2, required: true },
            { prompt: `
                <div style="border: 1px dashed #ccc; padding: 10px; border-radius: 5px; margin-bottom: 15px;">
                    <div class="label-container-0" id="label_0" style="display: ${shuffled_label_type[2] === 4 ? 'flex' : 'none'}">
                        <div class="label" id="label_0_text">该帖子无标签</div>
                    </div>
                    <div class="label-container-1" id="label_1_q" style="display: ${shuffled_label_type[2] === 1 || shuffled_label_type[2] === 2 ? 'flex' : 'none'}">
                        <span class="iconfont icon-info"></span>
                        <div class="label">平台声明：内容疑似AI生成，请谨慎甄别</div>
                        <div class="why-label" style="line-height: normal; text-align: start">平台检测工具识别出该文字信息疑似经过人工智能技术（AIGC）合成。</div>
                    </div>
                    <div class="title-container">
                        <div class="title-text">华为mate 70是否值得入手？</div>
                    </div>
                    <div class="info-container">
                        <div class="author-info">
                            <img src="avatar.png">
                            <div class="author-name" style="font-weight: 600;">用户</div>
                            <div class="date">编辑于2025-03-28</div>
                        </div>
                        <div class="label-container-2" id="label_2_q" style="display: ${shuffled_label_type[2] === 1 || shuffled_label_type[2] === 3 ? 'flex' : 'none'}">
                            <span class="iconfont icon-info"></span>
                            <div class="label">作者声明：内容使用AI创作</div>
                            <div class="why-label" style="line-height: normal; text-align: start">此提示语为"作者自主添加"，作者提示"该内容由人工智能生成技术（AIGC）创作"。</div>
                        </div>
                    </div>
                </div>
                <div style="margin-top: 20px;">请描述您对下述说法的认同程度<br>“阅读本文时，看到所显示的标签我感到不舒服”</div>
                `,  
                name: 'P3Q3_L'+ shuffled_label_type[2], labels: likert_scale3, required: true }
        ],
        label_type: shuffled_label_type[2] // 为帖子3分配随机的标签类型
    },
    4: {
        scales: [
            { prompt: "您认为此篇帖子的可信度为：", name: 'P4Q1_L'+ shuffled_label_type[3], labels: likert_scale1, required: true },
            { prompt: "您认为此篇帖子的真实作者是：", name: 'P4Q2_L'+ shuffled_label_type[3], labels: likert_scale2, required: true },
            { prompt: `
                <div style="border: 1px dashed #ccc; padding: 10px; border-radius: 5px; margin-bottom: 15px;">
                    <div class="label-container-0" id="label_0" style="display: ${shuffled_label_type[3] === 4 ? 'flex' : 'none'}">
                        <div class="label" id="label_0_text">该帖子无标签</div>
                    </div>
                    <div class="label-container-1" id="label_1_q" style="display: ${shuffled_label_type[3] === 1 || shuffled_label_type[3] === 2 ? 'flex' : 'none'}">
                        <span class="iconfont icon-info"></span>
                        <div class="label">平台声明：内容疑似AI生成，请谨慎甄别</div>
                        <div class="why-label" style="line-height: normal; text-align: start">平台检测工具识别出该文字信息疑似经过人工智能技术（AIGC）合成。</div>
                    </div>
                    <div class="title-container">
                        <div class="title-text">什么是“隐形肥胖”？</div>
                    </div>
                    <div class="info-container">
                        <div class="author-info">
                            <img src="avatar.png">
                            <div class="author-name" style="font-weight: 600;">用户</div>
                            <div class="date">编辑于2025-03-28</div>
                        </div>
                        <div class="label-container-2" id="label_2_q" style="display: ${shuffled_label_type[3] === 1 || shuffled_label_type[3] === 3 ? 'flex' : 'none'}">
                            <span class="iconfont icon-info"></span>
                            <div class="label">作者声明：内容使用AI创作</div>
                            <div class="why-label" style="line-height: normal; text-align: start">此提示语为"作者自主添加"，作者提示"该内容由人工智能生成技术（AIGC）创作"。</div>
                        </div>
                    </div>
                </div>
                <div style="margin-top: 20px;">请描述您对下述说法的认同程度<br>“阅读本文时，看到所显示的标签我感到不舒服”</div>
                `, 
                name: 'P4Q3_L'+ shuffled_label_type[3], labels: likert_scale3, required: true }
        ],
        label_type: shuffled_label_type[3] // 为帖子4分配随机的标签类型
    }
};


// 获取DOM元素
const posts = document.querySelectorAll('.item-container');
const overlay = document.getElementById('overlay');
const modal = document.getElementById('modal');
const questionnaireContent = document.getElementById('questionnaire-content');
const closeModalButton = document.getElementById('close-modal');

let jsPsych; // 改为let以便重新初始化

// 创建一个时间线数组
const timeline = [];

// 用于记录已完成的试次
const completedTrials = new Set();

// 初始化jsPsych
jsPsych = initJsPsych({
    display_element: 'questionnaire-content',
    on_finish: () => {
        console.log('当前试次结束');
        // 检查是否所有帖子已完成
        if (completedTrials.size === posts.length) {
            // 所有帖子已完成，运行 end 试次
            jsPsych.run(timeline.slice(timeline.length-1, timeline.length));
            console.log('end');
    }
    }
});

// 为每个帖子创建一个试次并添加到时间线中
posts.forEach(post => {
    const postId = post.getAttribute('data-id');
    const questions = questionnaires[postId].scales;
    const description = descriptions[postId];
    const title = post_titles[postId];
    const labelType = questionnaires[postId].label_type;

    const trial = {
        type: jsPsychSurveyLikert,
        questions: questions,
        randomize_question_order: false,
        button_label: '提交',
        on_start: () => {
            // 更新指导语
            document.getElementById('description-text').textContent = description;
            document.getElementById('title-text').textContent = title;
            // 根据标签类型控制标签的显示
            const label0 = document.getElementById('label_0');
            const label1 = document.getElementById('label_1');
            const label2 = document.getElementById('label_2');


            if (labelType === 1) {
                label0.style.display = 'none';
                label1.style.display = 'flex';
                label2.style.display = 'flex';
            } else if (labelType === 2) {
                label0.style.display = 'none';
                label1.style.display = 'flex';
                label2.style.display = 'none';
            } else if (labelType === 3) {
                label0.style.display = 'none';
                label1.style.display = 'none';
                label2.style.display = 'flex';
            } else if (labelType === 4) {
                label0.style.display = 'flex';
                label1.style.display = 'none';
                label2.style.display = 'none';
            }


            // 显示弹窗
            showModal();

            // 新增代码：滚动左侧面板到顶部
            const leftPanel = document.querySelector('.left-panel');
            if (leftPanel) {
                leftPanel.scrollTop = 0;
            }
            
            // 重置右侧面板状态
            const rightquestions = document.getElementById('questionnaire-content');
            if (rightquestions) {
                rightquestions.scrollTop = 0;
            }
            const rightPanel = document.querySelector('.right-panel');
            rightPanel.style.display = 'none';
            rightPanel.classList.remove('active');
            document.querySelector('.modal-content').classList.remove('right-active');

            // 确保问卷容器在右侧面板内
            const questionnaireContent = document.getElementById('questionnaire-content');
            questionnaireContent.style.display = 'flex';
        },
        on_finish: () => {
            // 获取当前帖子
            const post = document.querySelector(`.item-container[data-id="${postId}"]`);
            // 禁用帖子并改变样式
            disablePost(post);
            // 关闭弹窗
            closeModal();
            // 标记该试次为已完成
            completedTrials.add(postId);
        }
    };

    timeline.push(trial);
});


let end = {
    type: jsPsychHtmlKeyboardResponse,
    stimulus: '<p">实验结束</p>',  // 此处的stimulus是摆设，呈现在display_element: 'questionnaire-content'中
    trial_duration: 3000,
    choices: "NO_KEYS",
    on_start: () => {
        // 创建一个全屏元素
        const fullscreenElement = document.createElement('div');
        fullscreenElement.style.position = 'fixed';
        fullscreenElement.style.top = '0';
        fullscreenElement.style.left = '0';
        fullscreenElement.style.width = '100%';
        fullscreenElement.style.height = '100%';
        fullscreenElement.style.backgroundColor = 'white';
        fullscreenElement.style.display = 'flex';
        fullscreenElement.style.justifyContent = 'center';
        fullscreenElement.style.alignItems = 'center';
        fullscreenElement.style.zIndex = '10000'; // 确保在最上层
        fullscreenElement.id = 'fullscreen-end';
        document.body.appendChild(fullscreenElement);

        // 将 stimulus 插入全屏元素，通过全屏元素呈现结束语stimulus
        fullscreenElement.innerHTML = '<p style="font-size: 48px;">实验结束，感谢参与！</p>';

        // 关闭所有弹窗
        closeModal();
    }
  };
timeline.push(end);

// 添加点击事件监听器
posts.forEach(post => {
    post.addEventListener('click', () => {
        const postId = post.getAttribute('data-id');
        if (!completedTrials.has(postId)) { // 确保未完成的试次才运行
            // 重置右侧面板状态
            const rightquestions = document.getElementById('questionnaire-content');
            if (rightquestions) {
                rightquestions.scrollTop = 0;
            }
            const rightPanel = document.querySelector('.right-panel');
            rightPanel.style.display = 'none';
            rightPanel.classList.remove('active');
            document.querySelector('.modal-content').classList.remove('right-active');
            
            // 清空问卷内容
            document.getElementById('questionnaire-content').innerHTML = '';

            // 重置左侧内容区域的滚动位置到顶部
            const leftPanel = document.querySelector('.left-panel');
            if (leftPanel) {
                leftPanel.scrollTop = 0;
            }
            
            jsPsych.run(timeline.slice(postId - 1, postId)); // 运行单个试次
        }
    });
});

// 获取完成阅读按钮
const readCompleteBtn = document.getElementById('read-complete-btn');

// 禁用帖子并改变样式
function disablePost(post) {
    // 禁用点击事件
    post.style.pointerEvents = 'none';
    // 添加样式类
    post.classList.add('completed-post');
    // 添加边框效果
    post.style.border = '2px solid rgba(0, 0, 0, 0.27)';
    post.style.borderRadius = '12px';
}
// 添加完成阅读按钮点击事件
readCompleteBtn.addEventListener('click', function() {
    const rightPanel = document.querySelector('.right-panel');
    const modal = document.getElementById('modal');
    const rightquestions = document.getElementById('questionnaire-content');
            if (rightquestions) {
                rightquestions.scrollTop = 0;
            }
    
    // 添加completed类来锁定按钮状态
    this.classList.add('completed');
    this.disabled = true; // 可选：禁用按钮防止重复点击

    // 显示右侧面板
    rightPanel.style.display = 'flex';
    
    // 调整弹窗宽度
    modal.style.width = '1040px'; // 调整为总宽度
    
    // 添加动画类
    setTimeout(() => {
        rightPanel.classList.add('active');
        modal.classList.add('right-active');
        
        // 延迟0.5秒后显示问卷内容
        setTimeout(() => {
            document.getElementById('questionnaire-content').style.opacity = '1';
        }, 500);
    }, 10);

    // 确保jsPsych内容可见
    document.getElementById('questionnaire-content').style.display = 'block';
    
    // 滚动到右侧面板顶部
    setTimeout(() => {
        rightPanel.scrollTop = 0;
        document.getElementById('questionnaire-content').scrollTop = 0;
    }, 50);
});


// 修改关闭弹窗函数
function closeModal() {
    // 先移除动画类
    modal.classList.remove('active');
    modal.classList.remove('right-active');

    overlay.style.display = 'none';
    modal.style.display = 'none';

    // 恢复 body 的滚动（可选）
    document.body.style.overflow = 'auto';

    // 重置右侧面板状态
    const rightPanel = document.querySelector('.right-panel');
    rightPanel.style.display = 'none';
    rightPanel.classList.remove('active');
    // 重置弹窗宽度
    modal.style.width = '520px';
    
    // 重置左侧面板位置
    const leftPanel = document.querySelector('.left-panel');
    leftPanel.style.transform = 'translateX(0)';

    // 重置问卷内容透明度
    document.getElementById('questionnaire-content').style.opacity = '0';
    
    // 重置完成阅读按钮状态
    const readCompleteBtn = document.getElementById('read-complete-btn');
    if (readCompleteBtn) {
        readCompleteBtn.classList.remove('completed');
        readCompleteBtn.disabled = false;
    }
}

// 显示弹窗的函数
function showModal() {
    overlay.style.display = 'block';
    modal.style.display = 'block';
    modal.style.width = '520px'; // 初始宽度设为左面板宽度
    
    // 锁定 body 的滚动（可选）
    document.body.style.overflow = 'hidden';

    // 初始化状态
    const rightPanel = document.querySelector('.right-panel');
    rightPanel.style.display = 'none';
    rightPanel.classList.remove('active');
    document.querySelector('.modal-content').classList.remove('right-active');


    // 延迟 10ms 触发动画（确保 DOM 已更新）
    setTimeout(() => {
        modal.classList.add('active');
    }, 10);
}

// 关闭弹窗按钮事件
closeModalButton.addEventListener('click', () => {
    closeModal(); // 仅关闭，不触发on_finish
});


// 获取所有的 <li> 元素
const sideBarItems = document.querySelectorAll('.side-bar .channel-list li');

// 为每个 <li> 添加点击事件监听器
sideBarItems.forEach(li => {
    li.addEventListener('click', () => {
        alert('请勿点击无关内容，请按照指导语进行测评');
    });
});

const scrollchannelItems = document.querySelectorAll('.scroll-channel .channel');
scrollchannelItems.forEach(scrollchannelItems => {
    scrollchannelItems.addEventListener('click', () => {
        alert('请勿点击无关内容，请按照指导语进行测评');
    });
});


// 获取 <div class='information-container'> 元素
const informationContainer = document.querySelector('.information-container');

// 为 <div class='information-container'> 添加点击事件监听器
if (informationContainer) {
    informationContainer.addEventListener('click', () => {
        alert('请勿点击无关内容，请按照指导语进行测评');
    });
}

// menu弹窗
// 获取菜单元素
const menu1 = document.querySelector('.menu_1');

// 获取新的弹窗和关闭按钮
const overlayMenu = document.getElementById('overlay-menu');
const modalMenu = document.getElementById('modal-menu');
const closeModalMenuButton = document.getElementById('close-modal-menu');

// 显示新的弹窗
function showMenuModal() {
  overlayMenu.style.display = 'block';
  modalMenu.style.display = 'block';

  // 锁定 body 的滚动（可选）
  document.body.style.overflow = 'hidden';
  // 添加动画效果
  setTimeout(() => {
    modalMenu.classList.add('active');
  }, 10);
}

// 关闭新的弹窗
function closeMenuModal() {
    // 恢复 body 的滚动（可选）
    document.body.style.overflow = 'auto';
    modalMenu.classList.remove('active');
    setTimeout(() => {
      overlayMenu.style.display = 'none';
      modalMenu.style.display = 'none';
    }, 300); // 匹配CSS过渡时间
}

// 为菜单添加点击事件监听器
if (menu1) {
    menu1.addEventListener('click', (e) => {
      e.stopPropagation(); // 阻止事件冒泡
      showMenuModal();
    });
  }

// 为关闭按钮添加点击事件监听器
if (closeModalMenuButton) {
    closeModalMenuButton.addEventListener('click', (e) => {
      e.stopPropagation();
      closeMenuModal();
    });
  }

// 点击遮罩层关闭弹窗
if (overlayMenu) {
    overlayMenu.addEventListener('click', (e) => {
      if (e.target === overlayMenu) {
        closeMenuModal();
      }
    });
  }
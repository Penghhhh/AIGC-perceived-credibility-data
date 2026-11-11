const DataName = 'expData50';

function submitSurvey() {  
    // 初始化一个对象来存储所有答案  
    let surveyData = {};  
    var form = document.getElementById('commentForm'); 
  
    // 假设页面上的评论数量未知，我们遍历所有可能的评论元素  
    // 注意：这里使用 querySelectorAll 来动态获取实际的评论数量  
    const comments = document.querySelectorAll('.comment');  
    comments.forEach((comment, index) => {  
        const commentIndex = index + 1; // 转换为从 1 开始的索引，与 EJS 模板中的 cnum 对应  
        surveyData[`c${commentIndex}`] = {};  
  
        for (let j = 0; j <= 6; j++) {  
            let radioButtons = document.querySelectorAll(`input[name="c${commentIndex}-q${j}"]`);  
            let selectedValue = null;  
  
            // 找到被选中的单选按钮  
            for (let button of radioButtons) {  
                if (button.checked) {  
                    selectedValue = button.value;  
                    break;  
                }  
            }  
            // 将答案存储到对应评论的问题中  
            surveyData[`c${commentIndex}`][`q${j}`] = selectedValue;  
        } 
    });  

    let detectiontrust = document.querySelectorAll(`input[name = overview]`);
    let detectionvalue = null;
    for(let button of detectiontrust){
        if(button.checked){
            detectionvalue = button.value;
            break;
        }
    }



    // 检查是否有漏答  
    if (!(form.checkValidity())) {  
        alert('存在漏答，无法提交！');  
        return; // 如果有漏答，则直接返回，不执行后续的数据保存操作  
    }  



    // 获取当前时间并格式化
    const now = new Date();
    const year = now.getFullYear();
    const month = ('0' + (now.getMonth() + 1)).slice(-2);
    const day = ('0' + now.getDate()).slice(-2);
    const hours = ('0' + now.getHours()).slice(-2);
    const minutes = ('0' + now.getMinutes()).slice(-2);
    const seconds = ('0' + now.getSeconds()).slice(-2);
    const currentTime = year + month + day + hours + minutes + seconds;

    var url_id;
    url_id = window.location.search;
    url_id = url_id.split('=')[1];

    // 构造包含时间戳的localStorage键  
    const key = `${DataName}_${url_id}_${currentTime}_${detectionvalue}`;  

    // 将对象转换为JSON字符串，并存储到localStorage中  
    localStorage.setItem(key, JSON.stringify(surveyData));  
  
    // 可选：显示一个确认消息或进行其他操作  
    alert('已提交，请返回测评首页完成余下商品的评论测评');  
}  


document.getElementById('downloadData').addEventListener('click', function() {  
    // 假设你以某种方式收集了所有相关的localStorage键  
    // 这里我们假设每个键都遵循 'surveyData_...' 的格式  
    let csvContent = 'subjectID,SubmitTime,itemID,CommentID,Question1,Question2,Question3,Question4,Question5,Question6,question0,AIdetection\n'; // CSV头部  
  
    // 遍历localStorage中的每个项  
    for (let i = 0; i < localStorage.length; i++) {  
        const key = localStorage.key(i);  
        if (key.startsWith(DataName + '_')) {  
            try {  
                const expData = JSON.parse(localStorage.getItem(key));  
                const subject_id = key.split('_')[0];
                const currentTime = key.split('_')[2];
                const item_id = key.split('_')[1];
                const AI_detection = key.split('_')[3];
                for (const commentId in expData) {  
                    const commentData = expData[commentId];  
                    csvContent += `${subject_id},${currentTime},${item_id},${commentId},${commentData.q1 || ''},${commentData.q2 || ''},${commentData.q3 || ''},${commentData.q4 || ''},${commentData.q5 || ''},${commentData.q6 || ''},${commentData.q0 || ''}, ${AI_detection}\n`;  
                }  
            } catch (e) {  
                console.error('Error parsing localStorage item:', e);  
            }  
        }  
    }  
  
    // 创建一个Blob对象，并指定文件类型为CSV  
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });  
  
    // 创建一个指向该blob的URL  
    const url = URL.createObjectURL(blob);  
  
    // 创建一个临时的a标签用于下载  
    const link = document.createElement('a');  
    link.href = url;  
    link.setAttribute('download', 'data.csv'); // 或者使用其他文件名  
    document.body.appendChild(link);  
    link.click();  
  
    // 清理工作  
    document.body.removeChild(link);  
    URL.revokeObjectURL(url);  
});
  

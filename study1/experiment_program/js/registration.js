/*
//学历-专业显示
function toggleMajorInput() {  
    var educationSelect = document.getElementById('education');  
    var majorInputDiv = document.getElementById('majorInput');  
      
    // 检查选中的学历是否需要显示专业输入框  
    if (['undergraduate', 'master', 'doctor'].includes(educationSelect.value)) {  
        majorInputDiv.style.display = 'block'; // 显示专业输入框  
    } else {  
        majorInputDiv.style.display = 'none'; // 隐藏专业输入框  
    }   
}
    */



// 储存用户填写的数据信息
document.addEventListener('DOMContentLoaded', function() {  
    var form = document.getElementById('registrationForm'); 
    var ALLregistrations =[]; 

    // 初始化：从localStorage加载已存储的数据  
    function loadRegistrations() {  
        for (let i = 0; i < localStorage.length; i++) {  
            const key = localStorage.key(i);  
            if (key.startsWith('registration_')) { // 假设所有存储的键都以'registration_'开头  
                const formDataJSON = localStorage.getItem(key);  
                const formData = JSON.parse(formDataJSON);  
                ALLregistrations.push(formData);  
            }  
        }  
    }  
  
    loadRegistrations(); // 页面加载时加载数据
  
    form.addEventListener('submit', function(event) {  
        event.preventDefault(); // 阻止表单的默认提交行为  

        // 获取当前时间并格式化
        const now = new Date();
        const year = now.getFullYear();
        const month = ('0' + (now.getMonth() + 1)).slice(-2);
        const day = ('0' + now.getDate()).slice(-2);
        const hours = ('0' + now.getHours()).slice(-2);
        const minutes = ('0' + now.getMinutes()).slice(-2);
        const seconds = ('0' + now.getSeconds()).slice(-2);
        const currentTime = year + month + day + hours + minutes + seconds;
  
        // 序列化表单数据为对象  
        const formData = {  
            name: document.getElementById('name').value,
            submitTime: currentTime,  
            studentid: document.getElementById('student_id').value,
            gender: document.querySelector('input[name="gender"]:checked').value,  
            age: document.getElementById('age').value,  
            major: document.getElementById('major').value,
            platformtrust1: document.querySelector('input[name="platformtrust_1"]:checked').value,
            platformtrust2: document.querySelector('input[name="platformtrust_2"]:checked').value,
            platformtrust3: document.querySelector('input[name="platformtrust_3"]:checked').value,
            platformtrust4: document.querySelector('input[name="platformtrust_4"]:checked').value
        };  
  
        if (!formData.name || !formData.studentid || !formData.gender || !formData.age || !formData.major 
            || !formData.platformtrust1 || !formData.platformtrust2 || !formData.platformtrust3 || !formData.platformtrust4 ) {  
            alert('请完整填写内容');  
            return;  
        }  else{
            window.location.href = 'portal.html'; // 跳转到门户页面
        }
  
        const uniqueKey = `registration_${currentTime}`;  
        const formDataJSON = JSON.stringify(formData);  
  
        // 将数据保存到LocalStorage
        localStorage.setItem(uniqueKey, formDataJSON);  
        ALLregistrations.push(formData); // 同时更新内存中的数组  
  
        // 可选：显示或处理存储的数据  
        console.log('数据已保存到LocalStorage:', uniqueKey, formDataJSON);  
  
        // 清除表单数据（可选）  
        form.reset();  
  
        // 提示用户数据已保存（可选）  
        alert('您的数据已保存，欢迎进入平台优质评论测评模式！');  
    });  


    document.getElementById('downloadCsv').addEventListener('click', function() {  
        let csvContent = "name,submitTime,studentid,gender,age,major,trust1,trust2,trust3,detection\n";  
        ALLregistrations.forEach(registration => {  
            csvContent += `${registration.name},${registration.submitTime},${registration.studentid},${registration.gender},${registration.age},` +
            `${registration.major},${registration.platformtrust1},${registration.platformtrust2},${registration.platformtrust3},${registration.platformtrust4}\n`;  
        });  
  
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });  
        const link = document.createElement("a");  
        link.href = window.URL.createObjectURL(blob);  
        link.setAttribute("download", "registrations_data.csv");  
        document.body.appendChild(link);  
        link.click();  
  
        document.body.removeChild(link);  
        window.URL.revokeObjectURL(link.href);  
    });  
});
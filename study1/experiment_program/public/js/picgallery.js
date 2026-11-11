// 轮播图
document.querySelectorAll('.thumbnail-pic').forEach(thumbnail => {  
    thumbnail.addEventListener('mouseover', function() {  
        const mainPic = document.querySelector('.mainPicWrap img');  
        const imgSrc = this.getAttribute('data-img'); // 获取data-img属性的值  
        mainPic.src = imgSrc; // 更新大图片的src  
    });  
});

//悬停边框保持
document.querySelectorAll('.thumbnail-pic').forEach(thumbnail => {  
    thumbnail.addEventListener('mouseover', function() {  
        // 移除其他所有小图片的.active类  
        document.querySelectorAll('.thumbnail-pic').forEach(other => {  
            if (other !== this) {  
                other.classList.remove('active');  
            }  
        });  
  
        // 为当前小图片添加.active类  
        this.classList.add('active');  
    }); 
}); 
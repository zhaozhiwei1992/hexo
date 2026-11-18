/* 文章元数据补全（构建期，不改源文件）
 *
 * 为什么需要：
 *  1. hexo 内置 open_graph 的 description 取值顺序是 page.description → page.excerpt → 正文前 200 字；
 *     没有 description 时会给出一段从标题/代码块开头的脏文本，这里让没有显式 description 的文章
 *     退化成"正文纯文本前 140 字"，社交分享卡片好看一些。
 *  2. open_graph 会把正文里所有 <img> 都塞成 og:image（十几张图 = 十几条标签），而分享平台只用第一张。
 *     这里算出 page.og_image（正文首图），并让 open_graph 只输出这一张。
 *  3. 不用 page.photos 存图：NexT 会拿 page.photos 渲染相册（post_gallery），会改变页面结构。
 *
 * 显式优先：front-matter 写了 description / og_image 就完全不覆盖（org 的 #+DESCRIPTION 由模板写入）。
 */

const IMG_RE = /<img\b[^>]*\bsrc\s*=\s*['"]([^'"]+)['"]/i;

hexo.extend.filter.register('after_post_render', post => {
  if (post.layout !== 'post') return;

  if (!post.og_image) {
    const m = IMG_RE.exec(post.content || '');
    // 只要绝对地址：相对路径经 open_graph 拼出来会指到站点根，多半 404
    if (m && /^https?:\/\//i.test(m[1])) post.og_image = m[1];
  }

  if (!post.description) {
    const raw = post.excerpt && post.excerpt.trim() ? post.excerpt : post.content || '';
    const text = raw
      .replace(/<pre[\s\S]*?<\/pre>/gi, ' ')
      .replace(/<figure[\s\S]*?<\/figure>/gi, ' ')
      .replace(/<[^>]+>/g, ' ')
      .replace(/&nbsp;/g, ' ')
      .replace(/&[a-z#0-9]+;/gi, '')
      .replace(/\s+/g, ' ')
      .trim();
    if (text) post.description = text.length > 140 ? `${text.slice(0, 140)}…` : text;
  }
});

// 只保留一张 og:image（顺带 og:description 也会用上面补好的 description）
const coreOpenGraph = hexo.extend.helper.get('open_graph');
if (!coreOpenGraph) {
  hexo.log.warn('[post-meta] 没拿到 hexo 内置 open_graph helper，og:image 去重未生效');
} else {
  hexo.extend.helper.register('open_graph', function(options = {}) {
    const ogImage = this.page && this.page.og_image;
    if (ogImage && !options.image && !options.images) {
      options = Object.assign({}, options, { image: ogImage });
    }
    return coreOpenGraph.call(this, options);
  });
}

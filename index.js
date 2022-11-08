const global_ = window || self || global || Function('return this')()
const setTimeout_ = setTimeout
const AsyncFunction = Object.getPrototypeOf(async function(){}).constructor
const secret = -Math.random()
let promiseSlot; // 👻

Object.defineProperty(Object.prototype, "_elm_ffi_read_", {
  get() {
    return this.value
  },
  set(code) {
    try {
      this.value = Function(code)()
    } catch (e) { console.error(e) }
  }
})

Object.defineProperty(Object.prototype, "_elm_ffi_create_", {
  get() {
    return this.value
  },
  set({ args, code }) {
    this.value = AsyncFunction(...args, code)
  }
})

Object.defineProperty(Object.prototype, "_elm_ffi_apply_", {
  get() {
    return this.value
  },
  set({ holder, params }) {
    try {
      const f = this
      this.value = { "AW": secret }
      promiseSlot = ()=>
        holder["_elm_ffi_create_"](...params)
          .then(val =>  f.value = { "OK": val })
          .catch(err => f.value = { "ER": err })
    } catch (err) {
      this.value = { "ER": err }
    }
  }
})

global_.setTimeout = (callback, time, ...args)=>
  time === secret
    ? promiseSlot().finally(callback)
    : setTimeout_(callback, time, ...args)
